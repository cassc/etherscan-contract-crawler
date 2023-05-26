// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CrazyCarl is ERC1155, Ownable {
    using Strings for string;
    using MerkleProof for bytes32[];

    bytes32 public root =
        0xca58eac98cf801780b3429b340c203bc9dc8a12fdf3b366c861cb65e8ca77dec;

    string public _baseURI =
        "ipfs://QmPEZGHQqUQpoTUknQ6ivxCRxQzyv3xgRJibHMnjCabeHC/";
    string public _contractURI =
        "ipfs://QmdrNApBH3WYuit8f7Dy4e3iRt6EbBa2LP7uPte2iVE7bt";

    uint256 public pricePerToken = 0.01 ether; //only for public sale
    bool public locked; //metadata lock
    mapping(uint256 => uint256) public tokensMinterTier; //tier 1 -> tokensMinted
    uint256 public tokensMinted = 0;
    uint256 public unlockedSupply = 933;
    uint256 public maxTiers = 3;
    mapping(address => uint256) public listPurchases; //keeps track of whitelist buys

    uint256 public publicSaleStartTime = 0;
    uint256 public publicSaleEndTime = 0;

    uint256 public whitelistStartTime = 1643983200;
    uint256 public whitelistEndTime = 1645192800;

    constructor() ERC1155(_baseURI) {}

    function adminMint(
        address receiver,
        uint256 tier,
        uint256 qty
    ) external onlyOwner {
        require(tier > 0 && tier <= maxTiers, "tier not in range");
        require(tokensMinterTier[tier] + qty <= 1111, "tier out of stock");
        require(tokensMinted + qty <= unlockedSupply, "out of stock");

        tokensMinterTier[tier] = tokensMinterTier[tier] + qty;
        tokensMinted = tokensMinted + qty;
        _mint(receiver, tier, qty, "");
    }

    //onlyWhitelists can claim
    function whitelistMint(
        uint256 tier,
        uint256 qty,
        uint256 tokenID, //tokenID is the max qty an address can get
        bytes32[] calldata proof
    ) external {
        require(tier > 0 && tier <= maxTiers, "tier not in range");
        require(
            listPurchases[msg.sender] + qty <= tokenID,
            "wallet limit reached"
        );
        require(tokensMinterTier[tier] + qty <= 1111, "tier out of stock");
        require(tokensMinted + qty <= unlockedSupply, "out of stock");
        require(isPurchaseValid(msg.sender, tokenID, proof), "invalid proof");
        require(whitelistStartTime < block.timestamp, "sale not started");
        require(whitelistEndTime > block.timestamp, "sale ended");
        listPurchases[msg.sender] += qty;

        tokensMinterTier[tier] = tokensMinterTier[tier] + qty;
        tokensMinted = tokensMinted + qty;
        _mint(msg.sender, tier, qty, "");
    }

    //anyone can buy, without any limits
    function publicBuy(uint256 tier, uint256 qty) external payable {
        require(tier > 0 && tier <= maxTiers, "tier not in range");
        require(tokensMinterTier[tier] + qty <= 1111, "tier out of stock");
        require(tokensMinted + qty <= unlockedSupply, "out of stock");
        require(pricePerToken * qty == msg.value, "exact amount needed");
        require(publicSaleStartTime < block.timestamp, "sale not started");
        require(publicSaleEndTime > block.timestamp, "sale ended");

        tokensMinterTier[tier] = tokensMinterTier[tier] + qty;
        tokensMinted = tokensMinted + qty;

        _mint(msg.sender, tier, qty, "");
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setBaseURI(string memory newuri) public onlyOwner {
        require(!locked, "locked functions");
        _baseURI = newuri;
    }

    function setContractURI(string memory newuri) public onlyOwner {
        require(!locked, "locked functions");
        _contractURI = newuri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function isPurchaseValid(
        address _to,
        uint256 _qty,
        bytes32[] memory _proof
    ) public view returns (bool) {
        // construct Merkle tree leaf from the inputs supplied
        bytes32 leaf = keccak256(abi.encodePacked(_to, _qty));

        // verify the proof supplied, and return the verification result
        return _proof.verify(root, leaf);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // withdraw the earnings to pay for the artists & devs :)
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reclaimERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function reclaimERC721(IERC721 erc721Token, uint256 id) public onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }

    function reclaimERC1155(
        IERC1155 erc1155Token,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        erc1155Token.safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount,
            ""
        );
    }

    //changes the price per token
    function setPricePerToken(uint256 _newPrice) external onlyOwner {
        pricePerToken = _newPrice;
    }

    //set up start and end whitelisted dates
    function setWhitelistSaleTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(_endTime > _startTime, "endtime > starttime");
        require(_endTime > block.timestamp, "endtime > block timestamp");
        whitelistStartTime = _startTime;
        whitelistEndTime = _endTime;
    }

    //set up start and end public mint dates
    function setPublicSaleTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(_endTime > _startTime, "endtime > starttime");
        require(_endTime > block.timestamp, "endtime > block timestamp");
        publicSaleStartTime = _startTime;
        publicSaleEndTime = _endTime;
    }

    //can add a new tier
    function setMaxTiers(uint256 _maxTiers) external onlyOwner {
        maxTiers = _maxTiers;
    }

    //starts a new unlock period
    function setNewUnlockPeriod(uint256 _qty, uint256 _price)
        external
        onlyOwner
    {
        unlockedSupply = _qty;
        pricePerToken = _price;
    }

    // and for the eternity!
    function lockMetadata() external onlyOwner {
        locked = true;
    }
}