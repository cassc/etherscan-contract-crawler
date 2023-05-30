// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";


contract TypicalTigers is ERC721Enumerable, Ownable, AccessControlEnumerable {
    bytes32 public constant PREMINTER_ROLE = keccak256("PREMINTER_ROLE");
    uint256 public mintPrice = 30000000000000000; //0.03 ETH
    uint256 public maxPurchase = 10;
    bool public saleIsActive = false;
    bool public presaleIsActive = false;

    uint256 public maxSupply = 3900;
    uint256 public maxPresale = 1500;

    string _baseTokenURI = "ipfs://QmTQmzBAysJjRdB6gwkXL9Uw3HCbxH8M333jYwqrR4q9Vw/";


    modifier preminterRoleAdminOnly() {
        bytes32 roleAdmin = getRoleAdmin(PREMINTER_ROLE);
        require(hasRole(roleAdmin, msg.sender), 'Access: account is not role admin');
        _;
    }

    event SaleActivation(bool isActive);

    event PresaleActivation(bool isActive);

    event WhitelistCleared();

    constructor() ERC721("Typical Tigers", "TPT") {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControlEnumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function addToWhitelist(address _account) external preminterRoleAdminOnly  {
        grantRole(PREMINTER_ROLE, _account);
    }

    function removeFromWhitelist(address _account) external preminterRoleAdminOnly {
        revokeRole(PREMINTER_ROLE, _account);
    }

    function batchAddToWhitelist(address[] calldata _addresses) external preminterRoleAdminOnly {
        for(uint256 i; i < _addresses.length; i++){
            grantRole(PREMINTER_ROLE, _addresses[i]);
        }
    }

    function clearWhitelist() external preminterRoleAdminOnly  {
        uint256  initialWhitelistCount = getRoleMemberCount(PREMINTER_ROLE);
        for (uint256 i = 0; i < initialWhitelistCount; i++) {
            uint256  currentWhitelistCount = getRoleMemberCount(PREMINTER_ROLE);
            if(currentWhitelistCount > 0){
                address member = getRoleMember(PREMINTER_ROLE, 0);
                revokeRole(PREMINTER_ROLE, member);
            } else {
                break;
            }

        }
        emit WhitelistCleared();
    }

    function isWhitelistedAccount(address _account) public view returns (bool) {
        return hasRole(PREMINTER_ROLE, _account);
    }



    function ownerMint(address _to, uint256 _count) external onlyOwner {
        require(
            totalSupply() + _count <= maxSupply,
            "Purchase would exceed max supply of Typical Tigers"
        );
        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(_to, mintIndex);
            }
        }
    }

    function presaleMint(address _to, uint256 _count) external onlyRole(PREMINTER_ROLE) payable {
        require(presaleIsActive, "Presale must be active to mint Typical Tiger");

        require(_count <= maxPurchase, "Can only mint 10 tokens at a time");

        require(
            _count <= maxPresale,
            "Purchase would exceed max supply of presale Typical Tigers"
        );

        require(
            totalSupply() + _count <= maxSupply,
            "Purchase would exceed max supply of Typical Tigers"
        );

        require(
            mintPrice * _count <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(_to, mintIndex);
                maxPresale -= 1;
            }
        }
    }

    function mint(address _to, uint256 _count) external payable {
        require(saleIsActive, "Sale must be active to mint Typical Tiger");

        require(_count <= maxPurchase, "Can only mint 10 tokens at a time");

        require(
            totalSupply() + _count <= maxSupply,
            "Purchase would exceed max supply of Typical Tigers"
        );
        require(
            mintPrice * _count <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < _count; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(_to, mintIndex);
            }
        }
    }

    function togglePresaleStatus() external onlyOwner {
        presaleIsActive = !presaleIsActive;
        emit PresaleActivation(presaleIsActive);
    }

    function toggleSaleStatus() external onlyOwner {
        saleIsActive = !saleIsActive;
        emit SaleActivation(saleIsActive);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;
    }

    function setMaxPresale(uint256 _maxPresale) external onlyOwner {
        maxPresale = _maxPresale;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getTotalSupply() external view returns (uint256) {
        return totalSupply();
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}