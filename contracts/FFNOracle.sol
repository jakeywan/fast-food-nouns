// SPDX-License-Identifier: GPL-3.0

/// @title Fast Food Nouns Oracle

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

import { IInbox } from "./external/arbitrum/Inbox.sol";
import { INounsToken } from './interfaces/INounsToken.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

// example: https://github.com/OffchainLabs/arbitrum-tutorials/blob/master/packages/greeter/contracts/ethereum/GreeterL1.sol
contract FFNOracle is Ownable {

  // Reference to FFN contract on L1, using to check ownership
  INounsToken public fastFoodNouns = INounsToken(0xFbA74f771FCEE22f2FFEC7A66EC14207C7075a32);

  // Address to send updates to
  address public arbisNounsContract;

  // Arbitrum inbox contract (on Rinkeby)
  IInbox public inbox = IInbox(0x578BAde599406A8fE3d24Fd7f7211c0911F5B29e);

  /**
   * @notice Send updated ownerOf data to Arbitrum.
   */
  function updateArbisNounOwner(
    uint256 tokenId,
    uint256 maxSubmissionCost,
    uint256 maxGas,
    uint256 gasPriceBid
  ) external payable returns (uint256) {
      // TODO: what if this is non-existent? Does it revert properly?
      address owner = fastFoodNouns.ownerOf(tokenId);

      // TODO: Working on this...
      bytes4 selector = bytes4(keccak256("updateOwner(uint256,address)"));
      bytes memory data = abi.encodeWithSelector(selector, tokenId, owner);
      
      uint256 ticketID = inbox.createRetryableTicket{value: msg.value}(
          arbisNounsContract,
          0,
          maxSubmissionCost,
          msg.sender,
          msg.sender,
          maxGas,
          gasPriceBid,
          data
      );

      // emit RetryableTicketCreated(ticketID);
      return ticketID;

    }

  /**
   * @notice Update L1 FFN contract address.
   */
  function updateFFNContract(address _contract) external onlyOwner {
      fastFoodNouns = INounsToken(_contract);
  }

  /**
   * @notice Update L2 oracle contract address.
   */
  function updateArbisNounsContract(address _contract) external onlyOwner {
    arbisNounsContract = _contract;
  }

  /**
   * @notice Update the Arbitrum relay inbox contract address.
   */
  function updateInboxContract(address _contract) external onlyOwner {
    inbox = IInbox(_contract);
  }

}