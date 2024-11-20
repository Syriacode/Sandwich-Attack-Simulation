// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SandwichAttackSimulation {
    // simulated token pool reserves
    uint256 public tokenAReserve = 1000; // Token A
    uint256 public tokenBReserve = 1000; // Token B

    // track profits for demonstration
    uint256 public botProfit;

    event Swap(address indexed trader, string tokenIn, uint256 amountIn, string tokenOut, uint256 amountOut);
    event AttackExecuted(uint256 botProfit);

    // get the price of Token A in terms of Token B
    function getPrice() public view returns (uint256) {
        return (tokenBReserve * 1e18) / tokenAReserve; // Scaled price
    }

    // swap function using constant product formula
    function swap(uint256 inputAmount, bool isTokenA) public returns (uint256 outputAmount) {
        require(inputAmount > 0, "Input amount must be greater than 0");

        if (isTokenA) {
            uint256 newAReserve = tokenAReserve + inputAmount;
            uint256 newBReserve = (tokenAReserve * tokenBReserve) / newAReserve;
            outputAmount = tokenBReserve - newBReserve;

            // Update reserves
            tokenAReserve = newAReserve;
            tokenBReserve = newBReserve;

            emit Swap(msg.sender, "Token A", inputAmount, "Token B", outputAmount);
        } else {
            uint256 newBReserve = tokenBReserve + inputAmount;
            uint256 newAReserve = (tokenAReserve * tokenBReserve) / newBReserve;
            outputAmount = tokenAReserve - newAReserve;

            // Update reserves
            tokenBReserve = newBReserve;
            tokenAReserve = newAReserve;

            emit Swap(msg.sender, "Token B", inputAmount, "Token A", outputAmount);
        }
    }

    // Execute a sandwich attack
    function executeSandwichAttack(uint256 victimAmount) public {
        uint256 initialPrice = getPrice();

        // Step 1: Front-run (buy Token B with Token A)
        uint256 frontRunAmount = 10; // Amount bot swaps
        uint256 botReceivedTokenB = swap(frontRunAmount, true); // Bot swaps Token A for Token B

        // Step 2: Victim performs their swap
        uint256 victimReceivedTokenB = swap(victimAmount, true);

        // Step 3: Back-run (sell Token B for Token A)
        uint256 botReceivedTokenA = swap(botReceivedTokenB, false);

        // Calculate bot profit
        botProfit += (botReceivedTokenA - frontRunAmount);

        uint256 finalPrice = getPrice();

        // Emit event for demonstration
        emit AttackExecuted(botProfit);

        // Log the attack details
        emit Swap(msg.sender, "Token A", frontRunAmount, "Token B", botReceivedTokenB);
        emit Swap(tx.origin, "Token A", victimAmount, "Token B", victimReceivedTokenB);
        emit Swap(msg.sender, "Token B", botReceivedTokenB, "Token A", botReceivedTokenA);
    }
}
