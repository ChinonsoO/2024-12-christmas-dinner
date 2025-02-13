//SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {ChristmasDinner} from "../../src/ChristmasDinner.sol";
import {ERC20Mock} from "../../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract Handler is Test {
    ChristmasDinner cd;
    ERC20Mock wbtc;
    ERC20Mock weth;
    ERC20Mock usdc;

    address user1;
    address user2;
    address user3;
    address deployer;

    constructor(ERC20Mock _wbtc, ERC20Mock _weth, ERC20Mock _usdc, ChristmasDinner _cd, address _user1, address _user2, address _user3, address _deployer){
        wbtc = _wbtc;
        weth = _weth;
        usdc = _usdc;
        cd = _cd;
        user1 = _user1;
        user2 = _user2;
        user3 = _user3;
        deployer = _deployer;
    }

    // function setUp() public {
    //     wbtc = new ERC20Mock();
    //     weth = new ERC20Mock();
    //     usdc = new ERC20Mock();
    //     vm.startPrank(deployer);
    //     cd = new ChristmasDinner(address(wbtc), address(weth), address(usdc));
    //     vm.warp(1);
    //     cd.setDeadline(DEADLINE);
    //     vm.stopPrank();
    //     _makeParticipants();
    // }

    function depositWbtc (uint256 amount) public {
        amount = bound(amount, 0, wbtc.balanceOf(user1));
        vm.startPrank(user1);
        wbtc.approve(address(cd), amount);
        if (block.timestamp > cd.deadline()){
            vm.expectRevert();
        }
        cd.deposit(address(wbtc), amount);
        
        vm.stopPrank();
    }

    function depositWeth (uint256 amount) public {
        amount = bound(amount, 0, weth.balanceOf(user1));
        vm.startPrank(user1);
        weth.approve(address(cd), amount);
        if (block.timestamp > cd.deadline()){
            vm.expectRevert();
        }
        cd.deposit(address(weth), amount);
       
        vm.stopPrank();
    }
    
    function depositUsdc (uint256 amount) public {
        amount = bound(amount, 0, usdc.balanceOf(user1));
        vm.startPrank(user1);
        usdc.approve(address(cd), amount);
        if (block.timestamp > cd.deadline()){
            vm.expectRevert();
        }
        cd.deposit(address(usdc), amount);
        vm.stopPrank();
    }

    function depositEth(uint256 amount) public {
        amount = bound(amount, 0, address(user1).balance);
        vm.startPrank(user1);
        if (block.timestamp > cd.deadline()){
                vm.expectRevert();
        }
        address(cd).call{value: amount}("");
        vm.stopPrank();
    }

    function refundBalance() public {
            vm.startPrank(user1);

            if (block.timestamp > cd.deadline()){
                vm.expectRevert();
            }
            cd.refund();
            vm.stopPrank();
    }

    function warpPastDeadline(uint256 warpAmount) public {
        // If your deadline is (deployedAt + X days),
        // you can choose a warp offset that surpasses it.
        warpAmount = bound(warpAmount, 1, 10); 
        warpAmount = warpAmount * 1 days;
        vm.warp(block.timestamp + warpAmount);
    }

    function changeHostToUser2() public {
        uint256 depositAmount = 1e18;
        require(weth.balanceOf(user2) >= depositAmount, "Insufficient WETH balance for user2");
        
        if (!cd.getParticipationStatus(user2)) {
            // Make user2 sign up by depositing a small amount of WETH.
            vm.startPrank(user2);
            weth.approve(address(cd), depositAmount);
            cd.deposit(address(weth), depositAmount);
            vm.stopPrank();
        }
        
        vm.startPrank(cd.getHost());
        cd.changeHost(user2);
        vm.stopPrank();

    }

    
}
