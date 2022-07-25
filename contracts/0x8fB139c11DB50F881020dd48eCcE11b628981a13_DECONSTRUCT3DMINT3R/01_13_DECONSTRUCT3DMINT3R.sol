// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";


contract DECONSTRUCT3DMINT3R is ERC1155, Ownable, ERC1155Supply, IERC2981 {
    uint256 public constant ROYALTIES_PERCENTAGE = 650; // 6.5%

    uint256[] public COLLECTION_IDS;
    mapping(uint256 => Token) public COLLECTION;

    mapping(uint => mapping(address => bool)) public ALLOWLIST;

    struct Token {
        uint256 id;
        string uri;
        string name;
        uint256 supply;
        bool public_minting;
        bool allowlist_minting;
        uint256 allowlist_price;
        uint256 public_price;
        bool allowlist_minting_open;
        bool public_minting_open;
    }

    constructor() ERC1155("") {
    }

    /* PUBLIC */

    function uri(uint256 id) public view virtual override returns (string memory) {
        return COLLECTION[id].uri;
    }

    function getCollectionIds() public view returns (uint256[] memory) {
        return COLLECTION_IDS;
    }

    function allowlistMint(address account, uint256[] memory ids, uint256[] memory amounts) public payable 
        mintAllowed(true, account, ids, amounts)
    {
        if (ids.length == 1) {
            _mint(account, ids[0], amounts[0], "");
        } else{
            _mintBatch(account, ids, amounts, "");
        }
    }

    function mint(address account, uint256[] memory ids, uint256[] memory amounts) public payable 
        mintAllowed(false, account, ids, amounts)
    {
        if (ids.length == 1) {
            _mint(account, ids[0], amounts[0], "");
        } else{
            _mintBatch(account, ids, amounts, "");
        }
    }


    /* ADMIN */

    function addToken(
        uint256 _id, 
        string memory _uri,
        string memory _name,
        uint256 _supply, 
        bool _public_minting, 
        bool _allowlist_minting,
        uint256 _allowlist_price, 
        uint256 _public_price
    ) public onlyOwner {
        Token storage token = COLLECTION[_id];
        require(token.id == 0, "TOKEN ID NOT EXISTS");

        token.id = _id;
        token.uri = _uri;
        token.name = _name;
        token.supply = _supply;
        token.public_minting = _public_minting;
        token.allowlist_minting = _allowlist_minting;
        token.allowlist_price = _allowlist_price;
        token.public_price = _public_price;
        COLLECTION_IDS.push(_id);
    }

    function editToken(
        uint256 _id, 
        string memory _uri,
        string memory _name,
        uint256 _supply, 
        bool _public_minting, 
        bool _allowlist_minting,
        uint256 _allowlist_price, 
        uint256 _public_price
    ) public onlyOwner {
        Token storage token = COLLECTION[_id];
        require(token.id == _id, "TOKEN ID NOT FOUND");

        token.uri = _uri;
        token.name = _name;
        token.supply = _supply;
        token.public_minting = _public_minting;
        token.allowlist_minting = _allowlist_minting;
        token.allowlist_price = _allowlist_price;
        token.public_price = _public_price;
    }

    function deleteToken(uint256 _id) public onlyOwner {
        Token storage token = COLLECTION[_id];
        require(token.id == _id, "TOKEN ID NOT FOUND");

        delete COLLECTION[_id];
        for (uint256 i; i<COLLECTION_IDS.length; i++) {
            if (COLLECTION_IDS[i] == _id) {
                COLLECTION_IDS[i] = COLLECTION_IDS[COLLECTION_IDS.length - 1];
                COLLECTION_IDS.pop();
                break;
            }
        }
    }

    function addAllowlist(uint _id, address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            ALLOWLIST[_id][_addresses[i]] = true;
        }
    }

    function deleteAllowlist(uint _id, address[] memory _addresses) public onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            ALLOWLIST[_id][_addresses[i]] = false;
        }
    }

    function openAllowlistMinting(uint256 id) public onlyOwner {
        COLLECTION[id].allowlist_minting_open = true;
    }

    function closeAllowlistMinting(uint256 id) public onlyOwner {
        COLLECTION[id].allowlist_minting_open = false;
    }

    function openPublicMinting(uint256 id) public onlyOwner {
        COLLECTION[id].public_minting_open = true;
    }

    function closePublicMinting(uint256 id) public onlyOwner {
        COLLECTION[id].public_minting_open = false;
    }

    function ownerMint(address account, uint256[] memory ids, uint256[] memory amounts) public payable
        onlyOwner 
        mintAllowed(false, msg.sender, ids, amounts)
    {
        if (ids.length == 1) {
            _mint(account, ids[0], amounts[0], "");
        } else{
            _mintBatch(account, ids, amounts, "");
        }
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    /* ROYALTIES */

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(totalSupply(_tokenId) > 0);
        return (owner(), (_salePrice * ROYALTIES_PERCENTAGE) / 10000); // 6.5%
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    /* INTERNAL */

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply) 
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /* MODIFIERS */

    modifier mintAllowed(bool allowlist, address _address, uint256[] memory ids, uint256[] memory amounts) {
        for (uint i = 0; i < ids.length; i++) {
            Token storage token = COLLECTION[ids[i]];
            require(token.id > 0, "TOKEN ID NOT FOUND");
            
            require(token.supply >= totalSupply(ids[i]) + amounts[i], "MAX SUPPLY");
            
            if (owner() != _address) {
                if (allowlist) {
                    require(token.allowlist_minting == true, "ALLOWLIST NOT AVAILABLE");
                    require(token.allowlist_minting_open == true, "ALLOWLIST CLOSED");
                    require(ALLOWLIST[token.id][_address], "NOT IN ALLOWLIST");
                    require(msg.value >= token.allowlist_price * amounts[i], "TRANSACTION VALUE");
                } else {
                    require(token.public_minting == true, "PUBLIC MINTING NOT AVAILABLE");
                    require(token.public_minting_open == true, "PUBLIC MINTING CLOSED");
                    require(msg.value >= token.public_price * amounts[i], "TRANSACTION VALUE");
                }
            }
        }
        _;
    }
}