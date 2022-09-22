// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Pyxis {
    function getToken(address) public view returns (uint256) {}
}

interface ReserveNFT {
    function mintReservedNFT(address to)
    external
    payable;
}

contract ARCStellars is ReserveNFT, ERC721, Ownable {
    Pyxis pyxis;
    bool public paused = true;
    bool public stopped = false;
    uint256 public constant mintPrice = 3 ether;

    using Counters for Counters.Counter;
    Counters.Counter private tokenId;
    Counters.Counter private reservedCount;
    Counters.Counter private burnedCount;
    address private _couponOwner;
    address private _accountOwner;
    uint256 public constant MAX_SUPPLY = 1688;
    uint256 public constant RESERVED_SUPPLY = 188;
    uint256 public maxPerUserSupply = 1;
    string private _baseUri = "";
    mapping(address => Counters.Counter) private whitelistClaimed;
    address public reserveContractAddress;

    string public STELLARS_PROVENANCE = "";
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    event BaseUri(string _from, string _to);

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct CouponData {
        uint256 expire;
    }

    constructor() ERC721("ARCStellars", "ARS") {
        _couponOwner = owner();
        _accountOwner = owner();
    }

    function setReserveContractAddress(address reserveContractAddress_) external onlyOwner {
        reserveContractAddress = reserveContractAddress_;
    }

    modifier onlyReserveContract() {
        require(reserveContractAddress == msg.sender, "The caller is not ReserveMint");
        _;
    }

    function mintReservedNFT(address to) override external payable
    onlyReserveContract {
        _mintAction(to);
    }

    function connectPyxis(address _pyxis) public onlyOwner {
        pyxis = Pyxis(_pyxis);
    }

    function hasPyxis() public view returns (bool) {
        return pyxis.getToken(msg.sender) > 0;
    }
    
    function setStopMint() external onlyOwner {
        stopped = true;
        if(startingIndex == 0) startingIndexBlock = block.number;
    }

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(stopped == true, "Mint not stopped");
        require(startingIndex == 0, "Starting index set already");
        startingIndexBlock = block.number;
    }

    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index set already");
        require(startingIndexBlock != 0, "Starting block index not set");
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % totalSupply();
        } else {
            startingIndex = uint(blockhash(startingIndexBlock)) % totalSupply();
        }
        if (startingIndex == 0) startingIndex = 1;
    }

    function setPerUserSupply(uint256 _value) external onlyOwner {
        maxPerUserSupply = _value;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        emit BaseUri(_baseUri, baseURI);
        _baseUri = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function setMintPaused(bool status) public onlyOwner {
        paused = status;
    }

    function setCouponOwner(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "CouponOwner: new owner is the zero address"
        );
        _couponOwner = newOwner;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        STELLARS_PROVENANCE = provenanceHash;
    }

    function setAccountOwner(address newOwner) public onlyOwner {
        _accountOwner = newOwner;
    }

    function isValidUser(CouponData memory meta, Coupon memory coupon)
        public
        view
        returns (bool)
    {
        return _isValidCoupon(msg.sender, meta, coupon);
    }

    function _isValidCoupon(
        address to,
        CouponData memory meta,
        Coupon memory coupon
    ) private view returns (bool) {
        require(block.timestamp < meta.expire, "Coupon expired");

        bytes32 digest = keccak256(abi.encode(to, meta.expire));
        address signer = ECDSA.recover(digest, coupon.v, coupon.r, coupon.s);
        return (signer == _couponOwner);
    }

    function airdropToken(address[] memory list) public onlyOwner {
        require(
            reservedCount.current() + list.length <= RESERVED_SUPPLY,
            "Maximum reserved supply reached"
        );
        for(uint256 i = 0; i < list.length; i++) {
            reservedCount.increment();
            address to = list[i];
            _mintAction(to);
        }
    }

    function airdropRemainingSupply(address to, uint256 limit) public onlyOwner {
        require(stopped == false, "Mint stopped");
        require(paused == true, "Mint is not paused");
        uint256 remaingSupply = MAX_SUPPLY - tokenId.current();
        uint256 airdropLimit = (limit > remaingSupply)? remaingSupply: limit;
        for (uint256 i; i < airdropLimit; i++) {
            tokenId.increment();
            uint256 newId = tokenId.current();
            _safeMint(to, newId);
        }
    }

    function setBlockNumberOnLast() private {
        if (startingIndexBlock == 0 && (tokenId.current() == MAX_SUPPLY)) {
            startingIndexBlock = block.number;
            stopped = true;
        }
    }

    function _mintAction(address to)
        private
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        require(stopped == false, "Mint stopped");

        require(paused == false, "Mint paused");

        require(tokenId.current() < MAX_SUPPLY, "Total supply reached");

        tokenId.increment();
        uint256 newId = tokenId.current();
        whitelistClaimed[to].increment();
        setBlockNumberOnLast();
        _safeMint(to, newId);
        string memory newURI = super.tokenURI(newId); // @todo - remove
        return (newId, newURI, whitelistClaimed[to].current()); // @todo - remove
    }

    function claimedCount() public view returns (uint256) {
        return whitelistClaimed[msg.sender].current();
    }

    function _remainingPublicSupply()  private view returns ( uint256) {
        return MAX_SUPPLY - RESERVED_SUPPLY - (tokenId.current() - reservedCount.current());
    }

    function mint(CouponData memory meta, Coupon memory coupon)
        public
        payable
        returns (
            uint256,
            string memory,
            uint256
        )
    {
        require(
            _remainingPublicSupply() > 0,
            "Maximum supply reached"
        );

        require(
            _isValidCoupon(msg.sender, meta, coupon),
            "Non whitelisted user"
        );

        require(msg.value >= mintPrice, "Not enough eth sent.");

        require(hasPyxis(), "No pyxis found");

        require(
            whitelistClaimed[msg.sender].current() < maxPerUserSupply,
            "Per user supply reached"
        );

        return _mintAction(msg.sender);
    } 

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "balance is 0 ");
        payable(_accountOwner).transfer(address(this).balance);
    }

    function totalSupply() public view returns (uint256) {
        return tokenId.current() - burnedCount.current();
    }

    /**
    * The following functions are overrides 
    */
    function _beforeTokenTransfer(address from, address to, uint256 _tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, _tokenId);
        if (to == address(0)) burnedCount.increment();
    }
}