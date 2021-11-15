// SPDX-License-Identifier: GPL-3.0

/// @title Fast Food Nouns Oracle
/// @notice Broadcasts L1 `ownerOf` data to L2

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░████████████░░░░░░░░░░░ *
 * ░░░░░░██████░█░███░░░░░░░░░░░ *
 * ░░░░███████░█░█░██████░░░░░░░ *
 * ░░░████████░░░░░██████░░░░░░░ *
 * ░░░████████████████████████░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import "./external/arbitrum/Inbox.sol";

// example: https://github.com/OffchainLabs/arbitrum-tutorials/blob/master/packages/greeter/contracts/ethereum/GreeterL1.sol
contract ArbisOracle {

  // Reference to FFN contract on L1, using to check ownership
  INounsToken public fastFoodNouns = INounsToken(0xFbA74f771FCEE22f2FFEC7A66EC14207C7075a32);

  // Address to send updates to
  address public arbisNounsContract;

  IInbox public inbox;

  /**
   * @notice Send updated ownerOf data to Arbitrum.
   */
  function updateArbisNounOwner(
    uint256 tokenId,
    uint256 maxSubmissionCost,
    uint256 maxGas,
    uint256 gasPriceBid
  ) external returns (uint256) {
      // TODO: what if this is non-existent? Does it revert properly?
      address memory owner = fastFoodNouns.ownerOf(tokenId);

      // TODO: I'm not sure if this is the right way to go from address -> bytes
      bytes memory data = abi.encode(tokenId, owner);
      
      uint256 ticketID = inbox.createRetryableTicket{value: msg.value}(
          l2Target,
          0,
          maxSubmissionCost,
          msg.sender,
          msg.sender,
          maxGas,
          gasPriceBid,
          data
      );

      emit RetryableTicketCreated(ticketID);
      return ticketID;

    }

  }

  /**
   * @notice Update FFN contract.
   */
  function updateFFNContract(address _contract) external onlyOwner {
      fastFoodNouns = INounsToken(_contract);
  }

}