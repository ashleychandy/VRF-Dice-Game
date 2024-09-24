// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@goplugin/contracts2_3/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@goplugin/contracts2_3/src/v0.8/VRFConsumerBaseV2.sol";

contract DiceGameAsh is VRFConsumerBaseV2 {

    uint256 private constant ROLL_IN_PROGRESS = 42;

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 s_keyHash = 0x2221f1de0709a1e37277f967f3731e42350e23f730a6a01c76534798481b357b;
    uint32 callbackGasLimit = 120000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    address vrfCoordinator = 0x57b8b03EaAd46C6E2e88dec6d1B6AE119621679f;

    mapping(uint256 => address) private s_rollers;
    mapping(address => uint256[]) private s_requests;
    mapping(address => uint256) private s_results;

    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);

    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function rollDice() public returns (uint256 requestId) {
        require(s_results[msg.sender] != ROLL_IN_PROGRESS, "Roll in progress");
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_rollers[requestId] = msg.sender;
        s_requests[msg.sender].push(requestId);
        s_results[msg.sender] = ROLL_IN_PROGRESS;
        emit DiceRolled(requestId, msg.sender);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 d6Value = (randomWords[0] % 6) + 1;
        address roller = s_rollers[requestId];
        s_results[roller] = d6Value;
        emit DiceLanded(requestId, d6Value);
    }

    function getDiceResult(address roller) public view returns (uint256) {
        require(s_results[roller] != ROLL_IN_PROGRESS, "Roll in progress");
        return s_results[roller];
    }

    function getRequestIds(address roller) public view returns (uint256[] memory) {
        require(s_results[roller] != ROLL_IN_PROGRESS, "Roll in progress");
        return s_requests[roller];
    }
}
