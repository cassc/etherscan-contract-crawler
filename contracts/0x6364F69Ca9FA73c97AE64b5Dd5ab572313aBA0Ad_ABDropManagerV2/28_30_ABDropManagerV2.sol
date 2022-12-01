//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ██████████████████████████████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                            ████████████████████████          ██████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//                                                    ████████████████████
//
//
//  █████╗ ███╗   ██╗ ██████╗ ████████╗██╗  ██╗███████╗██████╗ ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ██╔══██╗████╗  ██║██╔═══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ███████║██╔██╗ ██║██║   ██║   ██║   ███████║█████╗  ██████╔╝██████╔╝██║     ██║   ██║██║     █████╔╝
// ██╔══██║██║╚██╗██║██║   ██║   ██║   ██╔══██║██╔══╝  ██╔══██╗██╔══██╗██║     ██║   ██║██║     ██╔═██╗
// ██║  ██║██║ ╚████║╚██████╔╝   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
// ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//

/**
 * @title ABDropManagerV2
 * @author Anotherblock Technical Team
 * @notice This contract is responsible for creating and administrating new drops related to anotherblock.io
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/* Openzeppelin Contract */
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/* Optimism Contracts */
import {L1CrossDomainMessenger} from '@eth-optimism/contracts/L1/messaging/L1CrossDomainMessenger.sol';
import {IL1CrossDomainMessenger} from '@eth-optimism/contracts/L1/messaging/IL1CrossDomainMessenger.sol';

/* Custom Imports */
import {IAnother721} from './interfaces/IAnother721.sol';
import {ABErrors} from './errors/ABErrors.sol';

contract ABDropManagerV2 is Initializable, OwnableUpgradeable, ABErrors {
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev Array of existing Drops
    Drop[] public drops;

    /// @dev Gas limit for L2 tx
    uint32 private messengerGasLimit;

    /// @dev Address of anotherblock multisig
    address public treasury;

    /// @dev Address of anotherblock relay on Optimism
    address private relay;

    /// @dev L1 to L2 Messenger Contract
    IL1CrossDomainMessenger private messenger;

    /// @dev Storage gap provisioned for future upgrades (30 * 32 bytes)
    uint256[30] __gap;

    /// @dev Event emitted upon Drop creation
    event DropCreated(uint256 dropId);

    /// @dev Event emitted upon Drop update
    event DropUpdated(uint256 dropId);

    /**
     * @notice
     *  Drop Structure format
     *
     * @param dropId drop unique identifier
     * @param sold total number of sold tokens for this drop
     * @param rightHolderFee right Holder fee on each mint (to be divided by 1e6)
     * @param tokenInfo Token Info struct defining the token information (see TokenInfo structure)
     * @param owner right holder address
     * @param nft NFT contract address
     */
    struct Drop {
        uint256 dropId;
        uint256 sold;
        uint256 rightHolderFee;
        TokenInfo tokenInfo;
        address owner;
        address nft;
    }

    /**
     * @notice
     *  TokenInfo Structure format
     *
     * @param price initial price in ETH of 1 token
     * @param supply total number of tokens for this drop
     * @param royaltySharePerToken total percentage of royalty evenly distributed among tokens holders (to be divided by 1e6)
     */
    struct TokenInfo {
        uint256 price;
        uint256 supply;
        uint256 royaltySharePerToken;
    }

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  Contract Initializer
     *
     * @param _treasury treasury address
     * @param _messenger L2 Cross Domain Messenger contract address
     * @param _relay Anotherblock Relay contract address (On Optimism)
     */
    function initialize(
        address _treasury,
        address _messenger,
        address _relay
    ) public initializer {
        // Check that the parameters addresses are not the zero-address
        if (_treasury == address(0)) revert ZeroAddress();
        if (_messenger == address(0)) revert ZeroAddress();
        if (_relay == address(0)) revert ZeroAddress();
        __Ownable_init();

        treasury = _treasury;
        relay = _relay;
        messenger = L1CrossDomainMessenger(_messenger);
        messengerGasLimit = 1_500_000;

        _regenerateExistingDrops();
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Update the Drop `_dropId` with new `_quantity` recently sold
     *
     * @param _dropId drop identifier
     * @param _quantity quantity of NFT sold
     */
    function updateDropCounter(uint256 _dropId, uint256 _quantity) external {
        Drop storage drop = drops[_dropId];

        // Ensure that the caller is the NFT contract associated to this drop
        if (msg.sender != drop.nft) revert UnauthorizedUpdate();

        // Increment the sold quantity
        drop.sold += _quantity;
    }

    /**
     * @notice
     *  Relay NFT transfer data to L2 contracts
     *
     * @param _from previous holder address
     * @param _to new holder address
     * @param _dropId drop ID associated to the token transferred
     * @param _quantity amount of token transferred
     */
    function updateOnTransfer(
        address _from,
        address _to,
        uint256 _dropId,
        uint256 _quantity
    ) external {
        Drop memory drop = drops[_dropId];
        if (msg.sender != drop.nft) revert UnauthorizedUpdate();

        messenger.sendMessage(
            relay,
            abi.encodeWithSignature(
                'transferredNFT(address,address,uint256,uint256)',
                _from,
                _to,
                _dropId,
                _quantity
            ),
            messengerGasLimit
        );
    }

    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Create a Drop
     *  Only the contract owner can perform this operation
     *
     * @param _owner right holder address
     * @param _price initial price in ETH of 1 NFT
     * @param _supply total number of NFT for this drop
     * @param _royaltySharePerToken total percentage of royalty evenly distributed among NFT holders (to be divided by 1e6)
     * @param _rightHolderFee right Holder fee on each mint (to be divided by 1e6)
     * @param _baseFlow base amount of AB Token to be streamed per seconds
     * @param _nftAddress associated NFT contract address
     */
    function create(
        address _owner,
        uint256 _price,
        uint256 _supply,
        uint256 _royaltySharePerToken,
        uint256 _rightHolderFee,
        int96 _baseFlow,
        address _nftAddress
    ) external onlyOwner {
        // Enforce non-null royalty shares for this drop
        if (_royaltySharePerToken <= 0) revert InsufficientRoyalties();

        // Enforce non-null supply
        if (_supply <= 0) revert InsufficientSupply();

        // Ensure right holder address is not the zero address
        if (_owner == address(0)) revert ZeroAddress();

        // Ensure NFT address is not the zero address
        if (_nftAddress == address(0)) revert ZeroAddress();

        // Set NFT contract drop ID
        IAnother721(_nftAddress).setDropId(drops.length);

        // Create the drop
        _createDrop(
            _owner,
            _nftAddress,
            _rightHolderFee,
            _baseFlow,
            TokenInfo(_price, _supply, _royaltySharePerToken)
        );
    }

    /**
     * @notice
     *  Update the treasury address
     *  Only the contract owner can perform this operation
     *
     * @param _newTreasury new treasury address
     */
    function setTreasury(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert ZeroAddress();
        treasury = _newTreasury;
    }

    /**
     * @notice
     *  Update the Drop `_dropId` token information
     *  Only the contract owner can perform this operation
     *
     * @param _dropId drop identifier of the drop to be updated
     * @param _tokenInfo array containing the new token information to be updated
     */
    function setTokenInfo(
        uint256 _dropId,
        uint256[3] calldata _tokenInfo
    ) external onlyOwner {
        // Ensure supply non-null
        if (_tokenInfo[1] <= 0) revert InsufficientSupply();

        // Enfore non-null royalty shares for this drop
        if (_tokenInfo[2] <= 0) revert InsufficientRoyalties();

        // Get the drop to be updated
        Drop storage drop = drops[_dropId];

        // Update the price info
        drop.tokenInfo.price = _tokenInfo[0];

        // Update the royalty share info
        drop.tokenInfo.royaltySharePerToken = _tokenInfo[2];

        // Check if the Drop has never been minted
        if (drop.sold == 0) {
            // Update the supply info
            drop.tokenInfo.supply = _tokenInfo[1];

            messenger.sendMessage(
                relay,
                abi.encodeWithSignature(
                    'updatedDropSupply(uint256,uint256)',
                    _dropId,
                    _tokenInfo[1]
                ),
                messengerGasLimit
            );
        }

        // Emit Drop Update event
        emit DropUpdated(_dropId);
    }

    /**
     * @notice
     *  Update the Drop `_dropId` drop information
     *  Only the contract owner can perform this operation
     *
     * @param _dropId drop identifier of the drop to be updated
     * @param _rightHolderFee fees paid to right holder
     * @param _owner right holder address
     */
    function setRightHolderInfo(
        uint256 _dropId,
        uint256 _rightHolderFee,
        address _owner
    ) external onlyOwner {
        // Ensure right holder address is not the zero address
        if (_owner == address(0)) revert ZeroAddress();

        Drop storage drop = drops[_dropId];
        drop.rightHolderFee = _rightHolderFee;
        drop.owner = _owner;

        messenger.sendMessage(
            relay,
            abi.encodeWithSignature(
                'updatedDropRightholder(uint256,address)',
                _dropId,
                _owner
            ),
            messengerGasLimit
        );

        // Emit Drop Update event
        emit DropUpdated(_dropId);
    }

    /**
     * @notice
     *  Manually change the gas limit for L2 Cross Domain message
     *  Only the contract owner can perform this operation
     *
     * @param _gasLimit gas limit used by the cross domain messenger to relay the message to Optimism
     */
    function setGasLimit(uint32 _gasLimit) external onlyOwner {
        // Ensure right holder address is not the zero address
        if (_gasLimit == 0) revert IncorrectGasLimit();

        messengerGasLimit = _gasLimit;
    }

    /**
     * @notice
     *  Update the NFT address in the drop details of a given Drop
     *  Only the contract owner can perform this operation
     *
     * @param _dropId drop identifier of the drop to be updated
     * @param _nftAddress associated NFT contract address
     */
    function setDropNFT(
        uint256 _dropId,
        address _nftAddress
    ) external onlyOwner {
        // Ensure NFT address is not the zero address
        if (_nftAddress == address(0)) revert ZeroAddress();

        Drop storage drop = drops[_dropId];
        drop.nft = _nftAddress;
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Register the Drop information
     *
     * @param _owner right holder address
     * @param _nftAddress NFT contract address
     * @param _rightHolderFee right Holder fee on each mint expressed
     * @param _baseFlow base amount of AB Token to be streamed per seconds
     * @param _tokenInfo token information structure (see TokenInfo struct details)
     */
    function _createDrop(
        address _owner,
        address _nftAddress,
        uint256 _rightHolderFee,
        int96 _baseFlow,
        TokenInfo memory _tokenInfo
    ) internal {
        drops.push(
            Drop(
                drops.length,
                0,
                _rightHolderFee,
                _tokenInfo,
                _owner,
                _nftAddress
            )
        );

        messenger.sendMessage(
            relay,
            abi.encodeWithSignature(
                'createdDrop(int96,uint256,uint256,address)',
                _baseFlow,
                drops.length - 1,
                _tokenInfo.supply,
                _owner
            ),
            messengerGasLimit
        );

        // Emit Drop Creation event
        emit DropCreated(drops.length - 1);
    }

    /**
     * @notice
     *  Regenerate the first four Drops (post-upgrade)
     */
    function _regenerateExistingDrops() internal {
        // First 3 Drops parameters
        address[3] memory owners = [
            address(0x7Bed83806F969942431825588b6Bd389a3cEDf75),
            address(0x7Bed83806F969942431825588b6Bd389a3cEDf75),
            address(0x7Bed83806F969942431825588b6Bd389a3cEDf75)
        ];
        uint256[3] memory prices = [
            uint256(50000000000000000),
            uint256(85000000000000000),
            uint256(70000000000000000)
        ];
        uint256[3] memory supplies = [uint256(250), uint256(400), uint256(500)];
        uint256[3] memory royaltySharePerToken = [
            uint256(200),
            uint256(25),
            uint256(10)
        ];
        uint256[3] memory rightHolderFees = [
            uint256(1000000),
            uint256(1000000),
            uint256(1000000)
        ];
        int96[3] memory baseFlows = [int96(0), int96(0), int96(0)];

        // Create the genesis Empty Drop
        drops.push(Drop(0, 0, 0, TokenInfo(0, 0, 0), address(0), address(0)));

        // Emit Drop Creation event
        emit DropCreated(0);

        for (uint256 i = 0; i < 3; ++i) {
            // Create the drop
            drops.push(
                Drop(
                    drops.length,
                    supplies[i],
                    rightHolderFees[i],
                    TokenInfo(prices[i], supplies[i], royaltySharePerToken[i]),
                    owners[i],
                    address(0)
                )
            );

            messenger.sendMessage(
                relay,
                abi.encodeWithSignature(
                    'createdDrop(int96,uint256,uint256,address)',
                    baseFlows[i],
                    drops.length - 1,
                    supplies[i],
                    owners[i]
                ),
                messengerGasLimit
            );

            // Emit Drop Creation event
            emit DropCreated(drops.length - 1);
        }
    }
}