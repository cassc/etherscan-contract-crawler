// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Apsaras is ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 internal constant MAX_LIMIT = 452;
    uint256 internal constant MAX_SALE_LIMIT = 427;

    uint256 internal constant SALE_ONCE_LIMIT = 2;
    uint256 internal constant WL_ONCE_LIMIT = 2;

    uint256 private normalPrice;
    uint256 private wlPrice;
    string public baseURI;
    uint256 public wlStartTime;
    uint256 public wlEndTime;
    uint256 private mintCounter;
    address private proxyRegistryAddress;
    address private founderAddress;
    bool private reveal;
    mapping(address => uint256) private numWLMinted;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721A(_name, _symbol) {
        founderAddress = address(0x343D01894De90031331F6D5aF648535A10eC4B09);
        wlPrice = 0.0492 ether;
        normalPrice = 0.0735 ether;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setPrice(uint256 _wlPrice, uint256 _normalPrice) public onlyOwner {
        wlPrice = _wlPrice;
        normalPrice = _normalPrice;
    }

    function setWLTime(uint256 _wlStartTime, uint256 _wlEndTime)
        public
        onlyOwner
    {
        require(_wlStartTime < _wlEndTime, "invalid args");
        require(block.timestamp < _wlEndTime, "end time invalid");
        require(0 < _wlStartTime, "start time invalid");
        wlStartTime = _wlStartTime;
        wlEndTime = _wlEndTime;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _tos address of the future owner of the token
     */
    function mintTo(address[] calldata _tos, uint256 _amount) public onlyOwner {
        uint256 _mintedAmt = _totalMinted();
        uint256 _mintAmt = _tos.length * _amount;
        require(
            _mintedAmt + _mintAmt <= MAX_LIMIT,
            "Apsaras: reached max limit"
        );
        for (uint256 i = 0; i < _tos.length; i++) {
            address _to = _tos[i];
            _mint(_to, _amount, "", false);
        }
    }

    function wlMint(uint256 num, bytes calldata signature) public payable {
        require(
            mintCounter + num <= MAX_SALE_LIMIT,
            "Apsaras: reached max limit."
        );
        require(
            wlStartTime <= block.timestamp && block.timestamp < wlEndTime,
            "Apsaras: whitelist mint not started"
        );
        require(
            msg.value >= num * wlPrice,
            "Apsaras: whitelist mint price error, please check msg.value."
        );
        require(
            owner() ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature),
            "Apsaras: Signer address mismatch."
        );
        require(
            _numberMinted(_msgSender()) + num <= WL_ONCE_LIMIT,
            "Apsaras: WhiteList Account maximum mint allowance reached."
        );
        mintCounter += num;
        numWLMinted[_msgSender()] += num;
        _mint(_msgSender(), num, "", false);
        if (founderAddress != address(0)) {
            payable(founderAddress).transfer(msg.value);
        }
    }

    function mint(uint256 num) public payable {
        require(
            mintCounter + num <= MAX_SALE_LIMIT,
            "Apsaras: reached max limit at public sale"
        );

        require(
            wlEndTime > 0 && block.timestamp >= wlEndTime,
            "Apsaras: public sale not started"
        );
        require(
            num <= SALE_ONCE_LIMIT,
            "Apsaras: over maximum of NFT allowed per mint"
        );
        uint256 user_limit = SALE_ONCE_LIMIT + numWLMinted[_msgSender()];
        require(
            _numberMinted(_msgSender()) + num <= user_limit,
            "Apsaras: over maximum of NFT allowed per user"
        );
        require(
            msg.value >= num * normalPrice,
            "Apsaras: price error, please check price."
        );
        mintCounter += num;
        _mint(_msgSender(), num, "", false);
        if (founderAddress != address(0)) {
            payable(founderAddress).transfer(msg.value);
        }
    }

    function setFounderAddress(address _founderAddress) public onlyOwner {
        require(_founderAddress != address(0), "Apsaras: zero address");
        founderAddress = _founderAddress;
    }

    function setBaseURI(string calldata _baseURI_) public onlyOwner {
        baseURI = _baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return ERC721A.isApprovedForAll(owner, operator);
    }

    function setReveal(bool _reveal) public onlyOwner {
        reveal = _reveal;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (reveal) {
            return
                bytes(baseURI).length > 0
                    ? string(
                        abi.encodePacked(baseURI, tokenId.toString(), ".json")
                    )
                    : "";
        } else {
            return bytes(baseURI).length > 0 ? baseURI : "";
        }
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /** Token starts from token 1 */

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdrawMoney() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}