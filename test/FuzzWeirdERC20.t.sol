pragma solidity ^0.8.14;

import "src/FuzzWeirdERC20.sol";
import { MockVault } from "./MockVault.sol";

contract TestFuzzWeirdERC20 is FuzzWeirdERC20 {
    uint256 constant tokenSupply = 1000000e18;
    MockVault public vault;

    function setUp() public {
        deployTokens(address(0xBEEF), tokenSupply);
        vault = new MockVault();
        setSkip(uint256(9));
    }

    function testDeposit(uint256 tokenType, uint256 amount) external {
        tokenType = getTokenType(tokenType);
        (uint256 min, ) = tokenInputRange(tokenType);
        amount = bound(amount, min, tokenSupply);
        address holder = address(0xBEEF);
        address spender = address(vault);
        address token = runHappyScenario(tokenType, holder, spender, amount);
        uint256 vaultBalanceBefore = ERC20(token).balanceOf(spender);
        uint256 depositBefore = vault.deposits(holder);
        vm.prank(holder);
        vault.deposit(token, amount);
        uint256 depositAfter = vault.deposits(holder);
        assertEq(ERC20(token).balanceOf(spender), vaultBalanceBefore + depositAfter - depositBefore);
    }
}
