//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./eERC721.sol";
import "./eReentrantGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/***************************************
 * @author: 🍖                         *
 * @team:   Asteria                     *
 ****************************************/

contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BitzClub is ERC721("Bitz Club", "BITZ"), Ownable, nonReentrant {
    address public constant BURN_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);
    address public openSeaProxyRegistryAddress =
        0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    bool private isOpenSeaProxyActive = true;

    address public constant PUNKIE_ADDRESS =
        0xa0A7581F6DB997b5d7C775708B7AE86E352F753d;
    IERC1155 public constant OPENSEA_STORE =
        IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e);

    constructor() {
        _setBaseURI("https://bitzclub.vercel.app/api/");
    }

    /**
     * SETTERS
     */

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setIsOpenSeaProxyActive(bool _isActive) external onlyOwner {
        isOpenSeaProxyActive = _isActive;
    }

    function setOpenSeaProxyAddress(address _address) external onlyOwner {
        openSeaProxyRegistryAddress = _address;
    }

    /**
     * OVERRIDES
     */

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     *  USER FUNCTIONS
     */

    function fromOSToken(uint256 _id) internal pure returns (uint256) {
        uint256 id = (_id &
            0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >>
            40;
        if (id > 1705 && id < 705) revert("BITZ: Invalid Token ID");
        return id < 880 ? id - 704 : id - 705;
    }

    function claim(uint256[] calldata id) external reentryLock {
        if (id.length == 0) revert("BITZ: Invalid Amount");

        uint256[] memory _transfer_amounts = new uint256[](id.length);
        unchecked {
            for (uint256 i = 0; i < id.length; i++) {
                uint256 _id = fromOSToken(id[i]);
                _transfer_amounts[i] = (1);
                _mint(msg.sender, _id);
            }
            try
                OPENSEA_STORE.safeBatchTransferFrom(
                    msg.sender,
                    BURN_ADDRESS,
                    id,
                    _transfer_amounts,
                    ""
                )
            {} catch Error(string memory reason) {
                revert(reason);
            }
        }
    }

    /** @dev This emergency function allows punkie to mint for others that have unreachable Bitz */
    function punkieRecovery(address _a, uint256 _id) external {
        if (msg.sender != PUNKIE_ADDRESS) revert("BITZ: Not Punkie");
        uint256 OS_id = fromOSToken(_id);
        _mint(_a, OS_id);
    }
}