pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "weird-erc20/Approval.sol";
import "weird-erc20/ApprovalToZero.sol";
import "weird-erc20/BlockLIst.sol";

contract FuzzWeirdERC20 is Test {
    uint256 constant TYPES = 3;

    ApprovalRaceToken public art;

    ApprovalToZeroToken public artzt;

    BlockableToken public bt;

    modifier prank(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }
    
    function getToken(uint256 tokenType) internal view returns(address) {
        uint256 i = tokenType % TYPES;
        if( i == 0 ) {
            return address(art);
        } else if ( i == 1 ) {
            return address(artzt);
        } else if ( i == 2) {
            return address(bt);
        }
    }

    function deployTokens(address holder, uint256 supply) internal prank(holder){
        art = new ApprovalRaceToken(supply);
        artzt = new ApprovalToZeroToken(supply);
        bt = new BlockableToken(supply);

    }

    function runAnyScenario(uint256 tokenType, uint256 scenario, address holder, address usedBy, uint256 amount) internal returns(address){
        function(address,address,uint256) returns(address)[] memory f = getScenarios(tokenType);
        scenario = scenario % f.length;
        return f[scenario](holder, usedBy, amount);
    }

    function runHappyScenario(uint256 tokenType, address holder, address usedBy, uint256 amount) internal returns(address) {
        function(address,address,uint256) returns(address)[] memory f = getScenarios(tokenType);
        return f[0](holder, usedBy, amount);
    }

    function getScenarios(uint256 tokenType) internal returns(
        function(address,address,uint256) returns(address)[] memory f
    ){
        uint256 i = tokenType % TYPES;
        if(i == 0) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioApproval;
            return f;
        } else if(i == 1) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioApprovalToZero;
            return f;
       } else if(i == 2) {
            f = new function(address,address,uint256) returns(address)[](3);
            f[0] = scenarioNotBlocked;
            f[1] = scenarioBlockSrc;
            f[2] = scenarioBlockDst;
            return f;
       }
    }
    
    function scenarioApproval(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address){
        art.approve(spender, amount);
        assertEq(art.allowance(holder, spender), amount);
        return address(art);
    }

    function scenarioApprovalToZero(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        artzt.approve(spender, amount);
        assertEq(artzt.allowance(holder, spender), amount);
        return address(artzt);
    }

    function scenarioBlockSrc(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        bt.block(holder);
        bt.allow(spender);
        bt.approve(spender, amount);
        assertEq(bt.allowance(holder, spender), amount);
        return address(bt);
    }

    function scenarioBlockDst(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        bt.allow(holder);
        bt.block(spender);
        bt.approve(spender, amount);
        assertEq(bt.allowance(holder, spender), amount);
        return address(bt);
    }

    function scenarioNotBlocked(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        bt.allow(holder);
        bt.allow(spender);
        bt.approve(spender, amount);
        assertEq(bt.allowance(holder, spender), amount);
        return address(bt);
    }
}
