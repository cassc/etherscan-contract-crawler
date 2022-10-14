// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ██████████████▌          ╟██           ████████████████          j██████████████  //
//  ██████████████▌          ╟███           ███████████████          j██████████████  //
//  ██████████████▌          ╟███▌           ██████████████          j██████████████  //
//  ██████████████▌          ╟████▌           █████████████          j██████████████  //
//  ██████████████▌          ╟█████▌          ╙████████████          j██████████████  //
//  ██████████████▌          ╟██████▄          ╙███████████          j██████████████  //
//  ██████████████▌          ╟███████           ╙██████████          j██████████████  //
//  ██████████████▌          ╟████████           ╟█████████          j██████████████  //
//  ██████████████▌          ╟█████████           █████████          j██████████████  //
//  ██████████████▌          ╟██████████           ████████          j██████████████  //
//  ██████████████▌          ╟██████████▌           ███████          j██████████████  //
//  ██████████████▌          ╟███████████▌           ██████          j██████████████  //
//  ██████████████▌          ╟████████████▄          ╙█████        ,████████████████  //
//  ██████████████▌          ╟█████████████           ╙████      ▄██████████████████  //
//  ██████████████▌          ╟██████████████           ╙███    ▄████████████████████  //
//  ██████████████▌          ╟███████████████           ╟██ ,███████████████████████  //
//  ██████████████▌                      ,████           ███████████████████████████  //
//  ██████████████▌                    ▄██████▌           ██████████████████████████  //
//  ██████████████▌                  ▄█████████▌           █████████████████████████  //
//  ██████████████▌               ,█████████████▄           ████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./IResources.sol";

contract Resources is ERC1155, AdminControl, IResources {

    string constant public name = "LVCIDIA// RESOURCES";
    string constant public symbol = "RSRC";

    // Mapping for individual token URIs
    mapping (uint256 => string) internal _tokenURIs;
    // Mapping of token total supplies
    mapping(uint256 => uint256) private _totalSupply;
    // Mapping of token burned supplies, public to allow querying entire map
    mapping(uint256 => uint256) public _burnedSupply;

    // Royalty
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    constructor () ERC1155("") {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AdminControl, IERC165) returns (bool) {
        return
            interfaceId == type(IResources).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId) ||
            interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /**
     * @dev See {IResrouces-mint}
     */
    function mint(address to, uint256[] memory tokenIds, uint256[] memory amounts) external override onlyOwner {
        if (tokenIds.length == 1 && amounts.length == 1) {
             // Single mint
            _mint(to, tokenIds[0], amounts[0], new bytes(0));            
        } else if (tokenIds.length == amounts.length) {
            // Batch mint to same receiver
            _mintBatch(to, tokenIds, amounts, new bytes(0));
        } else {
            revert("Invalid input");
        }
        for (uint i = 0; i < tokenIds.length;) {
            _totalSupply[tokenIds[i]] += amounts[i];
            // burned supply is naturally 0 by default and does not need setting
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Total amount of tokens of resource with a given id.
     */
    function totalSupply(uint256 tokenId) external view virtual override returns (uint256) {
        return _totalSupply[tokenId];
    }

    /**
     * @dev Total amount of burned tokens of resource with a given id.
     */
    function burnedSupply(uint256 tokenId) external view override returns (uint256) {
        return _burnedSupply[tokenId];
    }

    /**
     * @dev See {IResrouces-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri_) external override adminRequired {
        _tokenURIs[tokenId] = uri_;
    }

    /**
     * @dev See {IResrouces-setTokenURIs}.
     */
    function setTokenURIs(uint256[] memory tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i = 0; i < tokenIds.length;) {
            _tokenURIs[tokenIds[i]] = uris[i];
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev See {IResourecs-burn}.
     */
    function burn(address account, uint256[] memory tokenIds, uint256[] memory amounts) public virtual override {
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "Caller is not owner nor approved");
        require(tokenIds.length == amounts.length && tokenIds.length > 0, "Invalid input");
        if (tokenIds.length == 1) {
            _burn(account, tokenIds[0], amounts[0]);
        } else {
            _burnBatch(account, tokenIds, amounts);
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
        _burnedSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        super._burnBatch(account, ids, amounts);
        uint256 length = ids.length;
        for (uint256 i = 0; i < length;) {
            _totalSupply[ids[i]] -= amounts[i];
            _burnedSupply[ids[i]] += amounts[i];
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev See {IERC1155-uri}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }
}