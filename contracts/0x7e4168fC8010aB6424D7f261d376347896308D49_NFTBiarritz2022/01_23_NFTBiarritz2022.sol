// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./EIP2981Royalties/ERC2981ContractWideRoyalties.sol";
import "./rarible/impl/RoyaltiesV2Impl.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";

contract NFTBiarritz2022 is ERC721, ERC2981ContractWideRoyalties, Ownable, RoyaltiesV2Impl {
    /*                                                                                                                                    
              @@@@@@@                                                                                                                                 
           @@@@@@@@@@@@@                                                                                                                              
         @@@@@@@@@@@@@@@@@                                                                                                                            
      @@@@@@@        @@@@@@@@                 @@@@@@@@                                                 @@@@@@@@@                                      
    @@@@@@       *      @@@@@@@            @@@@@@@@@@@@@  @@@@@ &@@@        @@@@#     @@@@  @@@(     @@@@@@@@@@@@@      @@@@     @@@@@  @@@     @@@   
 @@@@@@@@    @@@@@@@@    @@@@@@@@@        @@@@       @@@@ @@@@@@@@@@@@@  @@@@@@@@@@@  @@@@@@@@@@@@  @@@@            @@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@    @@@@@@@@                     @@@@       @@@@@@@@@@    @@@@%@@@@@@@@@@@@# @@@@    @@@@  @@@@   @@@@@@@@ @@@@@@@@@@@@ @@@@@    @@@@    @@@@
  @@@@@@@@    @@@@@@@    @@@@@@@          @@@@@     @@@@@ @@@@@    @@@@ @@@@          @@@@    @@@@  @@@@@      @@@@ @@@@         @@@@@    @@@@    @@@@
     @@@@@@            @@@@@@@              @@@@@@@@@@@(  @@@@@@@@@@@@@  @@@@@@@@@@   @@@@    @@@@    @@@@@@@@@@@    @@@@@@@@@@  @@@@@    @@@@    @@@@
       @@@@@@@@    @@@@@@@@                               @@@@@                                                                                       
          @@@@@@@@@@@@@@@                                 @@@@@                                                                                       
            @@@@@@@@@@                                    @@@@@                                                                                       
               @@@@@   

    NFT Biarritz 2022 is a smartcontract handcrafted by OpenGem, the standard for secure NFTs.
    OpenGem provides security tools to verify ownership and immutability of digital assets. We also advise leading organizations by performing audits on their NFT products.
    opengem.com
    */
    using Counters for Counters.Counter;

    mapping(address => bool) public whitelistClaimed;

    struct discountStruct {
        uint256 id;
        uint256 discount;
    }

    mapping(address => discountStruct) public couponStructs;
    address[] public ERC721List;
    address[] public ERC1155List;

    string public constant NFT_NAME = "NFT Biarritz 2022 Ticket";
    string public constant NFT_DESC =
        "This is the ticket access to NFT Biarritz 2022, on the 24th of August, the first edition.";

    string public constant FOR_FETCHING_ONLY =
        "https://fetch.opengem.com/nftbiarritz2022/metadata.json";
    string public constant PERSISTENT_IPFS_HASH =
        "QmVKcf5h1z1kureeNpsbafmxuCyRYrMTs9Pnro6VX7g3LW";
    string public constant PERSISTENT_ARWEAVE_HASH =
        "AxnqV14aVIzmTHj2IqXMZlS9dlSuSGS8Vb9-VSYpFtw";
    string public constant PERSISTENT_SHA256_HASH_PROVENANCE =
        "6b81d3d0dd4f1ad5d7d4031c890a8347f11d17b49e0c01adff04dbf835aee356";

    uint256 public basePrice = 80000000000000000;

    uint256 public maxSupply;
    bool public maxSupplyLocked = false;

    string public txHashImgData;
    bool public imgDataLocked = false;

    bool public sales = true;

    bytes32 public merkleRoot;
    address public paidWallet;
    uint96 constant public ROYALTY_PERCENTAGE = 1000;

    Counters.Counter private tokenIdCounter;

    event Mint(address minter, uint256 tokenId);
    event Data(string imagedata);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(address _paidWallet, uint256 _maxSupply, bytes32 _merkleRoot) ERC721("NFT Biarritz 2022", "NFTB22") {
        merkleRoot = _merkleRoot;
        maxSupply = _maxSupply;
        paidWallet = _paidWallet;
        tokenIdCounter.increment();
        _setRoyalties(paidWallet, ROYALTY_PERCENTAGE);
    }

    function toggleSales() public onlyOwner {
        sales = !sales;
    }

    function updateMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory) 
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return FOR_FETCHING_ONLY;
    }

    function quantityMinted() public view returns (uint256) {
        return tokenIdCounter.current() - 1;
    }
    
    function updateBasePrice(uint256 price) public onlyOwner {
        basePrice = price;
    }

    function updateMaxSupply(uint256 supply) public onlyOwner {
        require(!maxSupplyLocked, "Max Supply locked");
        maxSupply = supply;
    }

    function lockMaxSupply() public onlyOwner {
        maxSupplyLocked = true;
    }

    function setImgData(string calldata imagedata) public onlyOwner {
        emit Data(imagedata);
    }

    function setTxHashImgData(string memory txHash) public onlyOwner {
        require(!imgDataLocked, "Image data locked");
        txHashImgData = txHash;
    }

    function lockImgData() public onlyOwner {
        imgDataLocked = true;
    }

    function getBalanceOf721(address nft, address wallet)
        public
        view
        returns (uint256)
    {
        IERC721 ERC721Contract = IERC721(nft);
        return ERC721Contract.balanceOf(wallet);
    }

    function getBalanceOf1155(
        address nft,
        uint256 id,
        address wallet
    ) public view returns (uint256) {
        IERC1155 ERC1155Contract = IERC1155(nft);
        return ERC1155Contract.balanceOf(wallet, id);
    }

    function append721Coupon(address nft, uint256 discount) public onlyOwner {
        getBalanceOf721(nft, 0xdb8FFd3c97C1263ccf6AD75e43d46ecc65ef702a);
        ERC721List.push(nft);
        couponStructs[nft].discount = discount;
    }

    function append1155Coupon(
        address nft,
        uint256 id,
        uint256 discount
    ) public onlyOwner {
        getBalanceOf1155(nft, id, 0xdb8FFd3c97C1263ccf6AD75e43d46ecc65ef702a);
        ERC1155List.push(nft);
        couponStructs[nft].id = id;
        couponStructs[nft].discount = discount;
    }

    function getDiscount(address buyer) public view returns (uint256) {
        uint256 discount = 0;
        for (uint256 i = 0; i < ERC721List.length; i++) {
            uint256 balance = getBalanceOf721(ERC721List[i], buyer);
            if (balance >= 1) {
                if (discount < couponStructs[ERC721List[i]].discount) {
                    discount = couponStructs[ERC721List[i]].discount;
                }
            }
        }
        for (uint256 i = 0; i < ERC1155List.length; i++) {
            uint256 balance = getBalanceOf1155(
                ERC1155List[i],
                couponStructs[ERC1155List[i]].id,
                buyer
            );
            if (balance >= 1) {
                if (discount < couponStructs[ERC1155List[i]].discount) {
                    discount = couponStructs[ERC1155List[i]].discount;
                }
            }
        }
        return discount;
    }

    function getFinalPrice(address buyer) public view returns (uint256) {
        return basePrice - (getDiscount(buyer) * basePrice) / 100;
    }

    function freemint(bytes32[] calldata merkle) public {
        require(!whitelistClaimed[msg.sender], "Address has already freemint.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkle, merkleRoot, leaf), "Incorrect proof.");
        
        _mainMint(msg.sender, 1);
        whitelistClaimed[msg.sender] = true;
    }

    function mint(uint256 num) public payable {
        require(
            (msg.value >= getFinalPrice(msg.sender) * num),
            "Ether value sent is not correct"
        );
        _mainMint(msg.sender, num);

        payable(paidWallet).transfer(msg.value);
    }

    function emergencyMint(uint256 num) public payable {
        require(
            (msg.value >= basePrice * num),
            "Ether value sent is not correct"
        );
        _mainMint(msg.sender, num);

        payable(paidWallet).transfer(msg.value);
    }

    function _mainMint(address to, uint256 num) internal {
        require(tx.origin == to, "The caller is another contract"); 
        require(sales, "Sales are closed"); 
        require(quantityMinted() + num <= maxSupply, "Exceeds maximum supply");

        for (uint256 i; i < num; i++) {
            _setRaribleRoyalties(tokenIdCounter.current(), payable(paidWallet), ROYALTY_PERCENTAGE);
            _safeMint(to, tokenIdCounter.current());
            emit Mint(to, tokenIdCounter.current());
            emit PermanentURI(FOR_FETCHING_ONLY, tokenIdCounter.current());
            tokenIdCounter.increment();
        }
    }

    function _setRaribleRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981Base) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}