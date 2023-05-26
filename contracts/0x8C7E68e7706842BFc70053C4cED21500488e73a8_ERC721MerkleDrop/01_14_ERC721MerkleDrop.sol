// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";


contract ERC721MerkleDrop is ERC721, IERC2981 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // Defaults to 0x0 (merkle root)
    bytes32 immutable public root;

    address payable immutable public creatorFund;
    address payable immutable public creator;

    uint256 public immutable royaltyAsProportionOfSalePrice; // this value is scaled by the SCALING_FACTOR
    uint256 public immutable airdropDurationInSeconds;
    uint256 public immutable airdropStartBlockTimestamp;
    uint256 public constant SCALING_FACTOR = 10000;


    modifier checkIfAirdropExpired() {
        uint256 currentTimestamp = block.timestamp;
        uint256 expiryTimestamp = airdropDurationInSeconds + airdropStartBlockTimestamp;

        require(expiryTimestamp > currentTimestamp, "airdrop expired");

        _;
    }

    
    constructor(string memory name, string memory symbol, bytes32 merkleroot, address payable _creatorFund, address payable _creator, uint256 _royaltyAsProportionOfSalePrice, uint256 _airdropDurationInSeconds)
    ERC721(name, symbol)
    {
        root = merkleroot;
        creatorFund = _creatorFund;
        creator = _creator;
        royaltyAsProportionOfSalePrice = _royaltyAsProportionOfSalePrice;
        airdropDurationInSeconds = _airdropDurationInSeconds;
        airdropStartBlockTimestamp = block.timestamp;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        override
        view
        returns (address receiver, uint256 royaltyAmount) {

            // tokenId is not used in the calcualtion of the royalty amount but it is still an input to adhere to the eip-2981 standard
            // royalties are only accepted in ether
            // the receiver is the NFT contract (address of this contract)

            receiver = address(this);
            royaltyAmount = (salePrice * royaltyAsProportionOfSalePrice) / SCALING_FACTOR;
    }


    function totalSupply() public view returns (uint256) { 
        return _tokenSupply.current();
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token"); 

        // all successfully minted (airdropped) tokens have the same metadata
        return "ipfs://QmWBRf5pocNMMxtMu4UN5SeVjKw9WseWkEWbbd2LTeyLAq";
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is zero");

        uint256 amountToCreatorFund = balance / 2;
        uint256 amountToCreator = balance - amountToCreatorFund;

        // check if the transactions are successfully executed
        (bool successCreatorFund, ) = (creatorFund).call{value: amountToCreatorFund}("");
        (bool successCreator, ) = (creator).call{value: amountToCreator}("");

        require(successCreatorFund, "CFWF");
        require(successCreator, "CWF");
    }


    
    event RedeemVoltzUNI(bytes32[] proof, uint256 tokenId);


    function redeem(address account, string memory metadataURI, bytes32[] calldata proof)
    external checkIfAirdropExpired returns (uint256)
    {
        require(_verify(_leaf(account, metadataURI), proof), "Invalid merkle proof");

        uint256 tokenId = uint256(uint160(account));

        _tokenSupply.increment();
        _safeMint(account, tokenId);

        emit RedeemVoltzUNI(proof, tokenId);

        return tokenId;
    }

    function _leaf(address account, string memory metadataURI)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(metadataURI, account));
    }


    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }


}