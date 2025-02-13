//SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {ChristmasDinner} from "../../src/ChristmasDinner.sol";
import {ERC20Mock} from "../../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantTest is StdInvariant, Test {
    ChristmasDinner cd;
    ERC20Mock wbtc;
    ERC20Mock weth;
    ERC20Mock usdc;

    uint256 constant DEADLINE = 7;
    address deployer = makeAddr("deployer");
    address user1;
    address user2;
    address user3;

    mapping (address => uint256 ) wethStartingAmount;
    mapping (address => uint256 ) wbtcStartingAmount;
    mapping (address => uint256 ) usdcStartingAmount;
    mapping (address => uint256 ) ethStartingAmount;

    Handler handler;
    
    function setUp() public {
        wbtc = new ERC20Mock();
        weth = new ERC20Mock();
        usdc = new ERC20Mock();
        vm.startPrank(deployer);
        cd = new ChristmasDinner(address(wbtc), address(weth), address(usdc));
        vm.warp(1);
        cd.setDeadline(DEADLINE);
        vm.stopPrank();

        _makeParticipants();

        handler = new Handler(wbtc, weth, usdc, cd, user1, user2, user3);

        bytes4[] memory selectors = new bytes4[](5);

        selectors[0] = handler.depositWeth.selector;
        selectors[1] = handler.depositWbtc.selector;
        selectors[2] = handler.depositUsdc.selector;
        selectors[3] = handler.depositEth.selector;
        selectors[4] = handler.refundBalance.selector;

        targetContract(address(handler));
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

    }


    function statefulFuzz_UserRefundsExactlyHowMuchTheyDeposited() public {
        vm.startPrank(user1);
        cd.refund();
        vm.stopPrank();

        assert(wethStartingAmount[user1] == weth.balanceOf(user1));
        assert(wbtcStartingAmount[user1] == wbtc.balanceOf(user1));
        assert(usdcStartingAmount[user1] == usdc.balanceOf(user1));
    }

    function statefulFuzz_UserWhoDepositsIsMarkedAsParticipant() public {
        // vm.startPrank(user1);
        if (cd.getUserBalance(user1, address(weth)) > 0 ||
            cd.getUserBalance(user1, address(usdc)) > 0 ||
            cd.getUserBalance(user1, address(wbtc)) > 0 ||
            cd.etherBalance(user1) > 0
            ) {
                assertTrue(cd.getParticipationStatus(user1));
            }
        // vm.stopPrank();

    }   

     function statefulFuzz_OnlyAllowSignupsBeforeDeadline() public {
        // vm.startPrank(user1);
        if (cd.getUserBalance(user1, address(weth)) > 0 ||
            cd.getUserBalance(user1, address(usdc)) > 0 ||
            cd.getUserBalance(user1, address(wbtc)) > 0 ||
            cd.etherBalance(user1) > 0
            ) {
                assertTrue(cd.getParticipationStatus(user1));
            }
        // vm.stopPrank();

    }

    function invariant_NoNewSignupsOrRefundsAfterDeadline() public {
    // Only check when the current time is past the deadline.
    if (block.timestamp > cd.deadline()) {
        // Have user1 try to make a deposit for each supported token.
        vm.startPrank(user1);

        // Attempt deposit with WBTC.
        (bool depositSuccess, ) = address(cd).call(
            abi.encodeWithSelector(cd.deposit.selector, address(wbtc), 1)
        );
        assertTrue(!depositSuccess, "Deposit with WBTC allowed after deadline");

        // Attempt deposit with WETH.
        (depositSuccess, ) = address(cd).call(
            abi.encodeWithSelector(cd.deposit.selector, address(weth), 1)
        );
        assertTrue(!depositSuccess, "Deposit with WETH allowed after deadline");

        // Attempt deposit with USDC.
        (depositSuccess, ) = address(cd).call(
            abi.encodeWithSelector(cd.deposit.selector, address(usdc), 1)
        );
        assertTrue(!depositSuccess, "Deposit with USDC allowed after deadline");

        // Attempt a refund.
        (bool refundSuccess, ) = address(cd).call(
            abi.encodeWithSelector(cd.refund.selector)
        );
        assertTrue(!refundSuccess, "Refund allowed after deadline");

        vm.stopPrank();
    }
}  


    function _makeParticipants() internal {
        user1 = makeAddr("user1");
        wbtc.mint(user1, 2e18);
        weth.mint(user1, 2e18);
        usdc.mint(user1, 2e18);
        vm.deal(user1, 2e18);

        wethStartingAmount[user1] = 2e18;
        wbtcStartingAmount[user1] = 2e18;
        usdcStartingAmount[user1] = 2e18;
        ethStartingAmount[user1] = 2e18;

        vm.startPrank(user1);
        wbtc.approve(address(cd), 2e18);
        weth.approve(address(cd), 2e18);
        usdc.approve(address(cd), 2e18);
        vm.stopPrank();

        user2 = makeAddr("user2");
        wbtc.mint(user2, 2e18);
        weth.mint(user2, 2e18);
        usdc.mint(user2, 2e18);
        vm.deal(user2, 2e18);

        wethStartingAmount[user2] = 2e18;
        wbtcStartingAmount[user2] = 2e18;
        usdcStartingAmount[user2] = 2e18;
        ethStartingAmount[user2] = 2e18;

        vm.startPrank(user2);
        wbtc.approve(address(cd), 2e18);
        weth.approve(address(cd), 2e18);
        usdc.approve(address(cd), 2e18);
        vm.stopPrank();

        user3 = makeAddr("user3");
        wbtc.mint(user3, 2e18);
        weth.mint(user3, 2e18);
        usdc.mint(user3, 2e18);
        vm.deal(user3, 2e18);

        wethStartingAmount[user3] = 2e18;
        wbtcStartingAmount[user3] = 2e18;
        usdcStartingAmount[user3] = 2e18;
        ethStartingAmount[user3] = 2e18;

        vm.startPrank(user3);
        wbtc.approve(address(cd), 2e18);
        weth.approve(address(cd), 2e18);
        usdc.approve(address(cd), 2e18);
        vm.stopPrank();
    }

   
}
