// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "./interfaces/internal/INFTCollectionInitializer.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "./libraries/AddressLibrary.sol";
import "./interfaces/internal/ICollectionFactory.sol";

/**
 * @title A collection of NFTs by a single creator.
 * @notice All NFTs from this contract are minted by the same creator.
 * A 10% royalty to the creator is included which may be split with collaborators on a per-NFT basis.
 * @author batu-inal & HardlyDifficult
 */
contract NFTCollection is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    ERC721URIStorageUpgradeable
{
    //
    using AddressLibrary for address;
    using AddressUpgradeable for address;

    /**
     * @notice The baseURI to use for the tokenURI, if undefined then `ipfs://` is used.
     */
    address public admin;

    event Approve(
        address indexed owner,
        uint256 indexed token_id,
        bool approved
    );
    event OrderPlace(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed value
    );
    event CancelOrder(address indexed from, uint256 indexed tokenId);
    event ChangePrice(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed value
    );
    event Checking(
        uint256 indexed approvevalue,
        uint256 indexed fee,
        uint256 netamount,
        uint256 roy
    );
    using SafeMath for uint256;
    struct Order {
        uint256 tokenId;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Order)) public order_place;

    mapping(uint256 => mapping(address => bool)) public checkOrder;
    mapping(uint256 => uint256) public totalQuantity;
    mapping(uint256 => bool) public _operatorApprovals;
    mapping(uint256 => address) public _creator;
    mapping(uint256 => uint256) public _royal;
    mapping(string => address) private tokentype;
    uint256 private serviceValue;
    string private _currentBaseURI;
    uint256 public _tid;
    mapping(uint256 => mapping(address => uint256)) public balances;
    mapping(uint256 => Metadata) token_id;

    struct Metadata {
        string name;
        string ipfsimage;
        string ipfsmetadata;
    }

    modifier onlyAdmin() {
        require(admin == _msgSender(), "Not Admin");
        _;
    }

    /**
     * @notice Called by the contract factory on creation.
     * @param _name The collection's `name`.
     * @param _symbol The collection's `symbol`.
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _admin
    ) external initializer {
        admin = _admin;
        __ERC721_init(_name, _symbol);
        serviceValue = 25 * 1e17;
        tokentype["PKS"] = 0xccB76558015c7e2D354b5832bFbCF64657160eA0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mint(
        uint256 tokenId,
        string memory name,
        string memory ipfsimage,
        string memory ipfsmetadata,
        uint256 value,
        uint256 supply,
        uint256 royal
    ) public {
        token_id[tokenId] = Metadata(name, ipfsimage, ipfsmetadata);
        _creator[tokenId] = msg.sender;
        _safeMint(msg.sender, tokenId);
        _royal[tokenId] = royal.mul(1e18);

        balances[tokenId][msg.sender] = supply;
        if (value != 0) {
            _orderPlace(msg.sender, tokenId, value);
        }
        totalQuantity[tokenId] = supply;
    }

    function orderPlace(uint256 tokenId, uint256 _price) public {
        _orderPlace(msg.sender, tokenId, _price);
    }

    function _orderPlace(
        address from,
        uint256 tokenId,
        uint256 _price
    ) internal {
        require(balances[tokenId][from] > 0, "Is Not a Owner");
        Order memory order;
        order.tokenId = tokenId;
        order.price = _price;
        order_place[from][tokenId] = order;
        checkOrder[tokenId][from] = true;
        emit OrderPlace(from, tokenId, _price);
    }

    function get(uint256 tokenId)
        external
        view
        returns (string memory name, string memory ipfsimage)
    {
        require(_exists(tokenId), "token not minted");
        Metadata memory date = token_id[tokenId];
        ipfsimage = date.ipfsimage;
        name = date.name;
    }

    function calc(
        uint256 amount,
        uint256 royal,
        uint256 _serviceValue
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fee = pERCent(amount, _serviceValue);
        uint256 roy = pERCent(amount, royal);
        uint256 netamount = amount.sub(fee.add(roy));
        fee = fee.add(fee);
        return (fee, roy, netamount);
    }

    function pERCent(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        uint256 result = value1.mul(value2).div(1e20);
        return (result);
    }

    function salewithToken(
        address bidtoken,
        address bidaddr,
        uint256 amount,
        uint256 tokenId
    ) internal {
        uint256 val = pERCent(amount, serviceValue).add(amount);
        ERC20Upgradeable t = ERC20Upgradeable(bidtoken);
        uint256 approveValue = t.allowance(bidaddr, address(this));
        require(approveValue >= val, "Insufficient Balance");
        (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(
            amount,
            _royal[tokenId],
            serviceValue
        );
        require(
            approveValue >= _adminfee.add(roy.add(netamount)),
            "Insufficient Balance"
        );
        t.transferFrom(bidaddr, admin, _adminfee);
        t.transferFrom(bidaddr, _creator[tokenId], roy);
        t.transferFrom(bidaddr, msg.sender, netamount);
        tokenTrans(tokenId, msg.sender, bidaddr);
    }

    function saleTokenwithToken(
        string memory tokenAss,
        address from,
        uint256 tokenId,
        uint256 amount
    ) public {
        newtokenasbid(tokenAss, from, admin, amount, tokenId);
        if (checkOrder[tokenId][from] == true) {
            delete order_place[from][tokenId];
            checkOrder[tokenId][from] = false;
        }
        tokenTrans(tokenId, from, msg.sender);
    }

    function newtokenasbid(
        string memory tokenAss,
        address from,
        address _admin,
        uint256 amount,
        uint256 tokenId
    ) internal {
        uint256 val = pERCent(amount, serviceValue).add(amount);
        ERC20Upgradeable t = ERC20Upgradeable(tokentype[tokenAss]);
        uint256 approveValue = t.allowance(msg.sender, address(this));
        require(approveValue >= val, "Insufficient Balance");
        require(balances[tokenId][from] > 0, "Is Not a Owner");
        (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(
            amount,
            _royal[tokenId],
            serviceValue
        );
        t.transferFrom(msg.sender, _admin, _adminfee);
        t.transferFrom(msg.sender, _creator[tokenId], roy);
        t.transferFrom(msg.sender, from, netamount);
    }

    function _acceptBId(
        string memory tokenAss,
        address from,
        address owner,
        uint256 amount,
        uint256 tokenId
    ) internal {
        uint256 val = pERCent(amount, serviceValue).add(amount);
        ERC20Upgradeable t = ERC20Upgradeable(tokentype[tokenAss]);
        uint256 approveValue = t.allowance(from, address(this));
        emit Checking(approveValue, approveValue, approveValue, approveValue);
        require(approveValue >= val, "Insufficient Balance");
        require(balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(
            amount,
            _royal[tokenId],
            serviceValue
        );
        emit Checking(approveValue, _adminfee, netamount, roy);
        require(
            approveValue >= _adminfee.add(roy.add(netamount)),
            "Insufficient Balance"
        );
        t.transferFrom(from, owner, _adminfee);
        t.transferFrom(from, _creator[tokenId], roy);
        t.transferFrom(from, msg.sender, netamount);
    }

    function saleToken(
        address payable from,
        uint256 tokenId,
        uint256 amount
    ) public payable {
        _saleToken(from, tokenId, amount);
        saleTokenTransfer(from, tokenId);
    }

    function _saleToken(
        address payable from,
        uint256 tokenId,
        uint256 amount
    ) internal {
        uint256 val = pERCent(amount, serviceValue).add(amount);
        require(msg.value == val, "Insufficient Balance");
        require(
            amount == order_place[from][tokenId].price,
            "Insufficent found"
        );
        address payable create = payable(_creator[tokenId]);

        (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(
            amount,
            _royal[tokenId],
            serviceValue
        );
        _approve(msg.sender, tokenId);
        require(
            msg.value == _adminfee.add(roy.add(netamount)),
            "Insufficient Balance"
        );
        payable(admin).transfer(_adminfee);
        create.transfer(roy);
        from.transfer(netamount);
    }

    function saleTokenTransfer(address payable from, uint256 tokenId) internal {
        if (checkOrder[tokenId][from] == true) {
            delete order_place[from][tokenId];
            checkOrder[tokenId][from] = false;
        }
        tokenTrans(tokenId, from, msg.sender);
    }

    function tokenTrans(
        uint256 tokenId,
        address from,
        address to
    ) internal {
        _approve(msg.sender, tokenId);
        safeTransferFrom(from, to, tokenId);
    }

    function acceptBId(
        string memory bidtoken,
        address bidaddr,
        uint256 amount,
        uint256 tokenId
    ) public {
        _acceptBId(bidtoken, bidaddr, admin, amount, tokenId);
        if (checkOrder[tokenId][msg.sender] == true) {
            delete order_place[msg.sender][tokenId];
            checkOrder[tokenId][msg.sender] = false;
        }
        tokenTrans(tokenId, msg.sender, bidaddr);
    }

    function cancelOrder(uint256 tokenId) public {
        require(balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        delete order_place[msg.sender][tokenId];
        checkOrder[tokenId][msg.sender] = false;
        emit CancelOrder(msg.sender, tokenId);
    }

    function changePrice(uint256 value, uint256 tokenId) public {
        require(balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        require(value < order_place[msg.sender][tokenId].price);
        order_place[msg.sender][tokenId].price = value;
        emit ChangePrice(msg.sender, tokenId, value);
    }

    function burnToken(uint256 id) public {
        require(
            balances[id][msg.sender] == 1,
            "Your Not a Token Owner or insufficient Token Balance"
        );
        burn(id);
        if (balances[id][msg.sender] == 1) {
            if (checkOrder[id][msg.sender] == true) {
                delete order_place[msg.sender][id];
                checkOrder[id][msg.sender] = false;
            }
        }
    }

    function getServiceFee() public view returns (uint256) {
        return serviceValue;
    }

    function addID(uint256 value) public returns (uint256) {
        _tid = _tid + value;
        return _tid;
    }

    function getTokenAddress(string memory _type)
        public
        view
        returns (address)
    {
        return tokentype[_type];
    }

    function addTokenType(string memory _type, address tokenAddress)
        public
        onlyAdmin
    {
        _addTokenType(_type, tokenAddress);
    }

    function _addTokenType(string memory _type, address tokenAddress)
        internal
        onlyAdmin
    {
        tokentype[_type] = tokenAddress;
    }

    function setApproval(address operator, bool approved)
        public
        returns (uint256)
    {
        setApprovalForAll(operator, approved);
        uint256 id_ = addID(1).add(block.timestamp);
        emit Approve(msg.sender, id_, approved);
        return id_;
    }

    function safeMint(address to, uint256 tokenId) public onlyAdmin {
        _safeMint(to, tokenId);
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _currentBaseURI = baseURI;
    }

    /* function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    } */

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}