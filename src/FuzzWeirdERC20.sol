pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "weird-erc20/Approval.sol";
import "weird-erc20/ApprovalToZero.sol";
import "weird-erc20/BlockList.sol";
import "weird-erc20/HighDecimals.sol";
import "weird-erc20/LowDecimals.sol";
import "weird-erc20/MissingReturns.sol";
import "weird-erc20/NoRevert.sol";
import "weird-erc20/Pausable.sol";
import "weird-erc20/Reentrant.sol";
import "weird-erc20/ReturnsFalse.sol";
//import "weird-erc20/RevertToZero.sol" this conflicts with Reentrant because of typo
import "weird-erc20/RevertZero.sol";
import "weird-erc20/TransferFee.sol";
import "weird-erc20/TransferFromSelf.sol";
//import "weird-erc20/Uint96.sol";
import "weird-erc20/Upgradable.sol";
import "./ReentrantMock.sol";

contract FuzzWeirdERC20 is Test {
    uint256 constant TYPES = 13;

    ApprovalRaceToken public art;

    ApprovalToZeroToken public artzt;

    BlockableToken public bt;

    HighDecimalToken public hdt;

    LowDecimalToken public ldt;

    MissingReturnToken public mrt;

    NoRevertToken public nrt;

    PausableToken public pt;

    ReentrantToken public rt;

    ReturnsFalseToken public rft;

    //RevertToZeroToken public rtzt;

    RevertZeroToken public rzt;

    TransferFeeToken public tft;

    TransferFromSelfToken public tfst;

    //Uint96Token public ut;

    mapping(uint256 => bool) public skipping;

    modifier prank(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    function setSkip(uint256 tokenType) internal {
        tokenType = tokenType % TYPES;
        skipping[tokenType] = true;
    }

    function getTokenType(uint256 fuzzInput) internal view returns(uint256 tokenType) {
        tokenType = fuzzInput % TYPES;
        while(skipping[tokenType]) {
            tokenType++;
            tokenType %= TYPES;
        }
    }
    
    function getToken(uint256 tokenType) internal view returns(address) {
        if( tokenType == 0 ) {
            return address(art);
        } else if ( tokenType == 1 ) {
            return address(artzt);
        } else if ( tokenType == 2 ) {
            return address(bt);
        } else if ( tokenType == 3 ) {
            return address(hdt);
        } else if ( tokenType == 4 ) {
            return address(ldt);
        } else if ( tokenType == 5 ) {
            return address(mrt);
        } else if ( tokenType == 6 ) {
            return address(nrt);
        } else if ( tokenType == 7 ) {
            return address(pt);
        } else if ( tokenType == 8 ) {
            return address(rt);
        } else if ( tokenType == 9 ) {
            return address(rft);
        } else if ( tokenType == 10 ) {
            return address(rzt);
        } else if ( tokenType == 11 ) {
            return address(tft);
        } else if ( tokenType == 12 ) {
            return address(tfst);
        }
    }

    function tokenInputRange(uint256 tokenType) internal view returns(uint256, uint256) {
        if(tokenType == 10){
            return(1, type(uint256).max);
        } else if(tokenType == 11) { //transfeFeeToken
            return(1e18, type(uint256).max);
        } else {
            return(0, type(uint256).max);
        }
    }

    function deployTokens(address holder, uint256 supply) internal prank(holder){
        art = new ApprovalRaceToken(supply);
        artzt = new ApprovalToZeroToken(supply);
        bt = new BlockableToken(supply);
        hdt = new HighDecimalToken(supply);
        ldt = new LowDecimalToken(supply);
        mrt = new MissingReturnToken(supply);
        nrt = new NoRevertToken(supply);
        pt = new PausableToken(supply);
        rt = new ReentrantToken(supply);
        rft = new ReturnsFalseToken(supply);
        //rtzt = new RevertToZeroToken(supply);
        rzt = new RevertZeroToken(supply);
        tft = new TransferFeeToken(supply, 1e18); // set initial fee to 1
        tfst = new TransferFromSelfToken(supply);
        //ut = new Uint96Token(supply);
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
        if(tokenType == 0) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioApproval;
        } else if(tokenType == 1) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioApprovalToZero;
        } else if(tokenType == 2) {
            f = new function(address,address,uint256) returns(address)[](3);
            f[0] = scenarioNotBlocked;
            f[1] = scenarioBlockSrc;
            f[2] = scenarioBlockDst;
        } else if(tokenType == 3) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioHighDecimal;
        } else if(tokenType == 4) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioLowDecimal;
        } else if(tokenType == 5) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioMissingReturn;
        } else if(tokenType == 6) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioNoRevert;
        } else if(tokenType == 7) {
            f = new function(address,address,uint256) returns(address)[](2);
            f[0] = scenarioNotPaused;
            f[1] = scenarioPaused;
        } else if(tokenType == 8) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioReentrant;
        } else if(tokenType == 9) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioReturnsFalse;
        } else if(tokenType == 10) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioRevertZero;
        } else if(tokenType == 11) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioFeeToken;
        } else if(tokenType == 12) {
            f = new function(address,address,uint256) returns(address)[](1);
            f[0] = scenarioTransferFromSelf;
        }
        return f;
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

    function scenarioHighDecimal(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        hdt.approve(spender, amount);
        assertEq(hdt.allowance(holder, spender), amount);
        return address(hdt);
    }

    function scenarioLowDecimal(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        ldt.approve(spender, amount);
        assertEq(ldt.allowance(holder, spender), amount);
        return address(ldt);
    }

    function scenarioMissingReturn(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        mrt.approve(spender, amount);
        assertEq(mrt.allowance(holder, spender), amount);
        return address(mrt);
    }

    function scenarioNoRevert(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        nrt.approve(spender, amount);
        assertEq(nrt.allowance(holder, spender), amount);
        return address(nrt);
    }

    function scenarioPaused(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        pt.start();
        pt.approve(spender, amount);
        pt.stop();
        assertEq(pt.allowance(holder, spender), amount);
        return address(pt);
    }

    function scenarioNotPaused(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        pt.start();
        pt.approve(spender, amount);
        assertEq(pt.allowance(holder, spender), amount);
        return address(pt);
    }

    function scenarioReentrant(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        ReentrantMock mock = new ReentrantMock();
        rt.setTarget(address(mock), abi.encodePacked(mock.log.selector));
        rt.approve(spender, amount);
        assertEq(rt.allowance(holder, spender), amount);
        return address(rt);
    }

    function scenarioReturnsFalse(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        rft.approve(spender, amount);
        assertEq(rft.allowance(holder, spender), amount);
        return address(rft);
    }

    function scenarioRevertZero(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        rzt.approve(spender, amount);
        assertEq(rzt.allowance(holder, spender), amount);
        return address(rzt);
    }

    function scenarioFeeToken(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        tft.approve(spender, amount);
        assertEq(tft.allowance(holder, spender), amount);
        return address(tft);
    }

    function scenarioTransferFromSelf(
        address holder,
        address spender,
        uint256 amount
    ) internal prank(holder) returns(address) {
        tfst.approve(spender, amount);
        assertEq(tfst.allowance(holder, spender), amount);
        return address(tfst);
    }
}
