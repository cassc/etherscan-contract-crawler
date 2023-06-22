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
 * @title ERC721ABv2
 * @author Anotherblock Technical Team
 * @notice Anotherblock NFT standard
 **/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/* Openzeppelin Contract */
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

/* ERC721A Azuki Contract */
import {ERC721AUpgradeable} from 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';

/* Opensea Contracts */
import {OperatorFilterer} from 'closedsea/src/OperatorFilterer.sol';

/* Custom Imports */
import {IABDropManager} from './interfaces/IABDropManager.sol';

/// @dev Error thrown when trying to set a drop ID that is already set
error AlreadySet();

/// @dev Error thrown when trying to call a function with an incorrect caller
error UnauthorizedUpdate();

abstract contract ERC721ABv2 is
    ERC721AUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable
{
    //     _____ __        __
    //    / ___// /_____ _/ /____  _____
    //    \__ \/ __/ __ `/ __/ _ \/ ___/
    //   ___/ / /_/ /_/ / /_/  __(__  )
    //  /____/\__/\__,_/\__/\___/____/

    /// @dev AB Drop Manager address
    address public dropManager;

    /// @dev Drop Identifier
    uint256 public dropId;

    /// @dev Drop ID set enable flag
    bool public locked;

    /// @dev Opensea Registry filter enable flag
    bool public operatorFilteringEnabled;

    //     ______                 __                  __
    //    / ____/___  ____  _____/ /________  _______/ /_____  _____
    //   / /   / __ \/ __ \/ ___/ __/ ___/ / / / ___/ __/ __ \/ ___/
    //  / /___/ /_/ / / / (__  ) /_/ /  / /_/ / /__/ /_/ /_/ / /
    //  \____/\____/_/ /_/____/\__/_/   \__,_/\___/\__/\____/_/

    /**
     * @notice
     *  ERC721AB contract initializer
     *
     * @param _dropManager : Drop Manager contract address
     * @param _name : name of the NFT contract
     * @param _symbol : symbol / ticker of the NFT contract
     **/
    function __ERC721ABv2_init(
        address _dropManager,
        string memory _name,
        string memory _symbol
    ) internal initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        _registerForOperatorFiltering();
        dropManager = _dropManager;
        locked = false;
        operatorFilteringEnabled = true;
    }

    //     ______     __                        __   ______                 __  _
    //    / ____/  __/ /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //   / __/ | |/_/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  / /____>  </ /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /_____/_/|_|\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    /**
     * @notice
     *  Set the `_dropId`
     *
     * @param _dropId drop identifer to be set to
     */
    function setDropId(uint256 _dropId) external {
        if (msg.sender != dropManager) revert UnauthorizedUpdate();
        if (locked) revert AlreadySet();
        locked = true;
        dropId = _dropId;
    }

    /**
     * @notice
     *  Approve or remove `operator` as an operator for the caller.
     *
     * @param _operator the address to be approved to transfer the token
     * @param _approved the approval status to be set
     */
    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public override onlyAllowedOperatorApproval(_operator) {
        super.setApprovalForAll(_operator, _approved);
    }

    /**
     * @notice
     *  Gives permission to `_operator` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * @param _operator the address to be approved to transfer the token
     * @param _tokenId the token identifier to be approved
     */
    function approve(
        address _operator,
        uint256 _tokenId
    ) public payable override onlyAllowedOperatorApproval(_operator) {
        super.approve(_operator, _tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable override onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public payable override onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    //
    //     ____        __         ____
    //    / __ \____  / /_  __   / __ \_      ______  ___  _____
    //   / / / / __ \/ / / / /  / / / / | /| / / __ \/ _ \/ ___/
    //  / /_/ / / / / / /_/ /  / /_/ /| |/ |/ / / / /  __/ /
    //  \____/_/ /_/_/\__, /   \____/ |__/|__/_/ /_/\___/_/
    //               /____/

    /**
     * @notice
     *  Update dropManager address
     *  Only the contract owner can perform this operation
     *
     * @param _dropManager : new dropManager address
     */
    function setDropManager(address _dropManager) external onlyOwner {
        dropManager = _dropManager;
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    //   _    ___                 ______                 __  _
    //  | |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
    //  | | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  | |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    //  |___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    //     ____      __                        __   ______                 __  _
    //    /  _/___  / /____  _________  ____ _/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
    //    / // __ \/ __/ _ \/ ___/ __ \/ __ `/ /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
    //  _/ // / / / /_/  __/ /  / / / / /_/ / /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
    // /___/_/ /_/\__/\___/_/  /_/ /_/\__,_/_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }

    /**
     * @dev See {ERC721Enumerable-beforeTokenTransfer}.
     */
    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _startTokenId,
        uint256 _quantity
    ) internal override(ERC721AUpgradeable) {
        IABDropManager(dropManager).updateOnTransfer(
            _from,
            _to,
            dropId,
            _quantity
        );
    }
}