// ERC1155で、セール機能を持つコントラクト
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract REREI is ERC1155Burnable, ERC2981, ReentrancyGuard, Ownable, DefaultOperatorFilterer {
    string private _baseTokenURI;

    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public mintLimit;
    mapping(uint256 => mapping(address => uint256)) public claimed;
    mapping(uint256 => uint256) public price;
    mapping(uint256 => bool) public saleStart;
    mapping(uint256 => uint256) public totalSupply;
    mapping(address => bool) public allowedAddress;

    event Mint(uint256 tokenId, address walletAddress, uint256 quantity);

    constructor() ERC1155("") {
        _setDefaultRoyalty(owner(), 1000);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return string.concat(_baseTokenURI, Strings.toString(_id), ".json");
    }

    struct Role {
        address payable roleAddress;
        uint256 share; // 10000 = 100%
    }
    mapping(uint256 => Role[]) public tokenRoles;
    function setRoles(uint256 _tokenId, address payable[] memory _roleAddresses, uint256[] memory _shares) public {
        require(_roleAddresses.length == _shares.length, "Address and share arrays length must be the same");

        delete tokenRoles[_tokenId];

        for (uint256 i = 0; i < _roleAddresses.length;) {
            Role memory newRole;
            newRole.roleAddress = _roleAddresses[i];
            newRole.share = _shares[i];
            tokenRoles[_tokenId].push(newRole);

            unchecked {
                i++;
            }
        }
    }
    function getRoleSize(uint256 _tokenId) external view returns (uint256) {
        return tokenRoles[_tokenId].length;
    }

    // mint
    function mint(uint256 _tokenId, uint256 _quantity, address _receiver) public payable nonReentrant {
        require(
            msg.value == price[_tokenId] * _quantity,
            "Value sent does not meet price for NFT"
        );
        require(
            maxSupply[_tokenId] >= totalSupply[_tokenId] + _quantity,
            "maxSupply over."
        );
        if (!allowedAddress[msg.sender]) {
            require(
                mintLimit[_tokenId] >= _quantity + claimed[_tokenId][msg.sender],
                "mintLimit over."
            );
        }

        _mint(_receiver, _tokenId, _quantity, "");
        totalSupply[_tokenId] += _quantity;
        claimed[_tokenId][msg.sender] += _quantity;

        emit Mint(_tokenId, _receiver, _quantity);

        // sendValue
        uint256 balance = msg.value;
        if (tokenRoles[_tokenId].length == 0) {
            Address.sendValue(payable(owner()), balance);
        } else {
            for (uint256 i = 0; i < tokenRoles[_tokenId].length;) {
                Address.sendValue(
                    tokenRoles[_tokenId][i].roleAddress,
                    (balance * tokenRoles[_tokenId][i].share) / 10000
                );

                unchecked {
                    i++;
                }
            }
        }
    }

    function ownerMint(uint256 _tokenId, uint256 _quantity, address _receiver) public onlyOwner nonReentrant {
        require(
            maxSupply[_tokenId] >= totalSupply[_tokenId] + _quantity,
            "maxSupply over."
        );

        _mint(_receiver, _tokenId, _quantity, "");
        totalSupply[_tokenId] += _quantity;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    function setSaleStart(uint256 _tokenId, bool _state) external onlyOwner {
        saleStart[_tokenId] = _state;
    }

    function setPrice(uint256 _tokenId, uint256 _price) external onlyOwner {
        price[_tokenId] = _price;
    }

    function setMintLimit(uint256 _tokenId, uint256 _amount) external onlyOwner {
        mintLimit[_tokenId] = _amount;
    }

    function setMaxSupply(uint256 _tokenId, uint256 _amount) external onlyOwner {
        maxSupply[_tokenId] = _amount;
    }

    function setAllowedAddress(address _address, bool _state) external onlyOwner {
        allowedAddress[_address] = _state;
    }

    // Burn
    function burn(
        address,
        uint256 _tokenId,
        uint256 _amount
    ) public override(ERC1155Burnable) onlyOwner {
        require(totalSupply[_tokenId] >= _amount, "amount is incorrect.");

        totalSupply[_tokenId] -= _amount;
        super.burn(msg.sender, _tokenId, _amount);
    }

    function burnBatch(
        address,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) public override(ERC1155Burnable) onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length;) {
            uint256 tokenId = _tokenIds[i];
            uint256 amount = _amounts[i];
            require(totalSupply[tokenId] >= amount, "amount is incorrect.");

            totalSupply[tokenId] -= amount;
            unchecked {
                i++;
            }
        }

        super.burnBatch(msg.sender, _tokenIds, _amounts);
    }

    // OpenSea OperatorFilterer
    function setOperatorFilteringEnabled(bool _state) external onlyOwner {
        operatorFilteringEnabled = _state;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // Royality
    function setRoyalty(address _royaltyAddress, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_royaltyAddress, _feeNumerator);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }
}