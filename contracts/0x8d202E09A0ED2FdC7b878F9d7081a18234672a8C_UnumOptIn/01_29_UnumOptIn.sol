//SPDX-License-Identifier:  MIT
pragma solidity ^0.8.17;

import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";

import { IJBController } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController.sol";
import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import { IJBPaymentTerminal } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import { IJBRedemptionTerminal } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionTerminal.sol";
import { IJBFundingCycleStore } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol";
import { JBTokens } from "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
import { JBFundingCycleMetadata } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycleMetadata.sol";

import { IJB721Delegate } from "@jbx-protocol/juice-721-delegate/contracts/interfaces/IJB721Delegate.sol";


/**
 * @title UnumOptIn
 *
 * @dev This contract allows to opt-in from Constitution DAO 2 (CDAO2) to UnumDao using the NFT
 *
 */

contract UnumOptIn {

    /**
     * @notice The project id of the CDAO2 project
     */
    uint256 public immutable cdaoProjectId;
    
    /**
     * @notice The project ids of the UnumDao project
     */
    uint256 public immutable unumProjectId;

    /**
     * @notice The CDAO2 NFT contract
     */
    IERC721 public immutable CDAO2NFT;

    /**
     * @notice The UnumDao NFT contract
     */
    IERC721 public immutable UNUMNFT;

    /**
     * @notice The CDAO2 ETH terminal
     *
     * @dev Most likely the same as the UnumDAO terminal
     */
    IJBRedemptionTerminal public immutable CDAO2RedemptionTerminal;

    /**
     * @notice The UnumDao ETH terminal
     *
     * @dev Most likely the same as the CDAO2 terminal
     */
    IJBPaymentTerminal public immutable UNUMPaymentTerminal;

    /**
     * @notice This opt-in contract is based on the datasources/NFT contract used
     *         at deployment time. If the datasources/NFT contract changes, this
     *         contract needs to be redeployed.
     *
     * @param _unumProjectId The project id of the UnumDao project
     * @param _cdaoProjectId The project id of the CDAO2 project
     * @param _controller The controller of the UnumDao project
     */
    constructor(uint256 _unumProjectId, uint256 _cdaoProjectId , IJBController _controller) {
        unumProjectId = _unumProjectId;
        cdaoProjectId = _cdaoProjectId;

        // Get the current FC datasource addressess  
        (, JBFundingCycleMetadata memory _metadataUnum) = _controller.currentFundingCycleOf(_unumProjectId);
        (, JBFundingCycleMetadata memory _metadataCdao) = _controller.currentFundingCycleOf(_cdaoProjectId);

        CDAO2NFT = IERC721(_metadataCdao.dataSource);
        UNUMNFT = IERC721(_metadataUnum.dataSource);

        // Get the correct terminals
        IJBDirectory _directory = IJBDirectory(_controller.directory());

        UNUMPaymentTerminal = _directory.primaryTerminalOf(_unumProjectId, JBTokens.ETH);
        CDAO2RedemptionTerminal = IJBRedemptionTerminal(address(_directory.primaryTerminalOf(_cdaoProjectId, JBTokens.ETH)));
    }

    /**
     * @notice Opt-in from CDAO2 to UnumDao, using multiple CDAO2 NFTs
     *
     * @param _tokenIds The NFT ids to redeem while opt-ing
     */
    function optIn(uint256[] calldata _tokenIds) external {
        // Pull and approve all the tokens
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Pull cdao2 NFT to this address
            CDAO2NFT.transferFrom(msg.sender, address(this), _tokenIds[i]);
            
            // Approve the redemption delegate
            CDAO2NFT.approve(address(CDAO2RedemptionTerminal), _tokenIds[i]);
        }
        
        bytes memory _redemptionMetadata = abi.encode(bytes32(0), type(IJB721Delegate).interfaceId, _tokenIds);

        // Redeem (the NFT is transfered to this address to avoid a third transaction to give the redemption role)
        uint256 _reclaimedAmount = CDAO2RedemptionTerminal.redeemTokensOf(
            address(this),
            cdaoProjectId,
            0,
            JBTokens.ETH,
            0,
            payable(address(this)),
            "UnumDao opt-in",
            _redemptionMetadata
        );

        // Prepare the NFT Reward metadatas
        bool _dontMint = false;

        // If extra fund, accept them but don't mint with them -> if too low to get a tier, would then revert,
        // adding them without minting on the other hand increases every NFT's nominal.
        bool _expectMintFromExtraFunds = false;
        bool _dontOverspend = false; 

        uint8[] memory _tiersToMint = new uint8[](_tokenIds.length);
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            _tiersToMint[i] = uint8(_tokenIds[i] / 1_000_000_000);
        }

        bytes memory _mintingMetadata = abi.encode(
            bytes32(0),
            bytes32(0),
            type(IJB721Delegate).interfaceId,
            _dontMint,
            _expectMintFromExtraFunds,
            _dontOverspend,
            _tiersToMint
        );

        // Mint unumDao NFT with the ETH received
        UNUMPaymentTerminal.pay{value: _reclaimedAmount}(
            unumProjectId,
            _reclaimedAmount,
            JBTokens.ETH,
            msg.sender,
            0,
            false,
            "opt-in from CDAO2",
            _mintingMetadata
        );


    }

    /**
     * @notice Receive ETH when redeeming
     */
    receive() external payable {}


}