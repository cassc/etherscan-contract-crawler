// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISouvenir.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Souvenir is
    ISouvenir,
    ERC1155Supply,
    Ownable,
    AccessControl,
    Pausable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private metaBaseURL =
        "https://ipfs.io/ipfs/QmNzUReme8udrveFWppQpkmPD7yeyD2gs2AGeXPRkZwnbH/";
    string private metaFileExtension = ".json";

    string public constant name = "NFTOOSouvenir";
    string public constant symbol = "NFTOOS";

    constructor() ERC1155("") {
        _setRoleAdmin(MINTER_ROLE, keccak256(abi.encodePacked(msg.sender)));
    }

    function uri(
        uint256 _tokenid
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    metaBaseURL,
                    Strings.toString(_tokenid),
                    metaFileExtension
                )
            );
    }

    function changeMetaBaseURL(string memory _newurl) public onlyOwner {
        metaBaseURL = _newurl;
    }

    function changeMetaFileExtension(string memory _newext) public onlyOwner {
        metaFileExtension = _newext;
    }

    function mint(address _to, uint256 _tokenId, uint256 _amount) external {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Sender does not have the minter role"
        );
        _mint(_to, _tokenId, _amount, "");
    }

    function decimals() external pure returns (uint8) {
        return 0;
    }

    function grantMinterRole(address account) public onlyOwner {
        grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) public onlyOwner {
        revokeRole(MINTER_ROLE, account);
    }

    function setMinterRoleAdmin(bytes32 role, address admin) public onlyOwner {
        _setRoleAdmin(role, keccak256(abi.encodePacked(admin)));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return AccessControl.supportsInterface(interfaceId);
    }
}