// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IAsksV1_1.sol";
import "./IZoraModuleManager.sol";

contract ZoraAsks is Initializable {
    // Address of Zora V3 Module (Asks V1.1)
    address public zoraAsksV1_1;

    // Address of Zora Transfer Helper (ERC721)
    address public zoraTransferHelper;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __ZoraAsksV1_1_init(
        address _zoraAsksV1_1,
        address _zoraTransferHelper,
        address _zoraModuleManager
    ) internal onlyInitializing {
        zoraAsksV1_1 = _zoraAsksV1_1;
        zoraTransferHelper = _zoraTransferHelper;
        IZoraModuleManager(_zoraModuleManager).setApprovalForModule(
            _zoraAsksV1_1,
            true
        );
    }

    /// @notice Creates the ask for a given NFT using Zora V3 Module (Asks V1.1)
    /// @param _tokenId the tokenId to list for sale
    function _createAsk(
        uint256 _tokenId,
        uint256 _askPrice,
        address _sellerFundsRecipient,
        uint16 _findersFeeBps
    ) internal {
        IAsksV1_1(zoraAsksV1_1).createAsk(
            address(this),
            _tokenId,
            _askPrice, // 0.0111 ETH
            address(0),
            _sellerFundsRecipient,
            _findersFeeBps
        );
    }
}