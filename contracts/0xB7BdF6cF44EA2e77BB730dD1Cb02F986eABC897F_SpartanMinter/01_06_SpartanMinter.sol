// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@notice access control
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ISpartan721A.sol";


/* 
    @title Spartan Minting Function
    @notice ERC721-ready Spartan contract
    @author cryptoware.eth | Spartan
*/
contract SpartanMinter is Ownable, ReentrancyGuard{

    /// @notice the spartan 1155 initial contract
    address payable private spartan721AContract;
    /// @notice the mint price of each NFT
    uint256 public mintPrice;
    /// @notice the minimum price of ethereum in dollars
    uint256 private minEthPriceInDollars;
    /// @notice the maximum price of etherum in dollars
    uint256 private maxEthPriceInDollars;
    /// @notice root of the new Merkle tree
    bytes32 private _merkleRoot;
    /// @notice mapping mints per user
    mapping(address => uint256) mintsPerUser;
    /// @notice mapping for mintIdUsed
    mapping(bytes16 => bool) mintId;


    /// @notice Mint event to be emitted upon NFT mint
    event Minted(
        address indexed to,
        uint256 indexed startToken,
        uint256 quantity
    );

    /// @notice Event that indicates which mint id has been used during minting
    event MintIdUsed(bytes16 indexed mintId);


    /**
     * @notice contructor
     * @param spartan721AContract_ the address of the spartan contract used for minting
     * @param minEthPriceInDollars_ the minimum eth price in dollars that the contract will be able to accept
     * @param maxEthPriceInDollars_ the maximum eth price in dollars that the contract will be able to accept
     * @param mintPrice_ the mint price of the Spartan NFT
     * @param root_ is the verification proof showing that the user is capable of minting
     */
    constructor(
        address payable spartan721AContract_,
        uint256 minEthPriceInDollars_,
        uint256 maxEthPriceInDollars_,
        uint256 mintPrice_,
        bytes32 root_
    ) Ownable() {
      spartan721AContract = spartan721AContract_;
      minEthPriceInDollars = minEthPriceInDollars_;
      maxEthPriceInDollars = maxEthPriceInDollars_;
      mintPrice = mintPrice_;
      _merkleRoot = root_;
    }

    /**
     * @notice mints tokens based on parameters
     * @param to address of the user minting
     * @param proof_ verify if msg.sender is allowed to mint
     * @param mintId_ mint id used to mint
     * @param currentEthPrice the current ehtereum price in dollars
     **/
    function mint(
        address to,
        bytes32[] memory proof_,
        bytes16 mintId_,
        uint256 currentEthPrice
    ) external payable nonReentrant{
        // The received wei the minter sent
        uint256 received = msg.value;
        // The dollars being sent 
        uint256 dollarsExpected = mintPrice;
        // The minimum price of the nft willing to be passed (Dollars)
        uint256 minDollarsExpected = dollarsExpected-(dollarsExpected/100);
        // The maximum price of the nft willing to be passed (Dollars)
        uint256 maxDollarsExpected = dollarsExpected+(dollarsExpected/100); //Dollar
        // The user address cannot be equal to zero
        require(to != address(0), "SPTN: Address cannot be 0");
        // The minimum price of ethereum in dollars that can be sendt as a currentEthPrice
        require(currentEthPrice>= minEthPriceInDollars, "SPTN: Invalid ETH Price");
        // The maximum price of ethereum in dollars that can be sent as a currentEthPrice
        require(currentEthPrice<= maxEthPriceInDollars, "SPTN: Invalid ETH Price");
        // Check if the msg.value sent by the user is less than the minimum set by the 
        require(
            minDollarsExpected <= (received*currentEthPrice/1000000000000000000), //Dollar
            "SPTN: Dollars sent is less than the minimum"
        );
        require(
            (received*currentEthPrice/1000000000000000000)<=maxDollarsExpected, //Dollar
            "SPTN: Dollars sent is more than the maximum"
        );
        require(
            ISpartan721A(spartan721AContract).totalSupply()+1 <= ISpartan721A(spartan721AContract).maxId(),
            "SPTN: max SPARTAN token limit exceeded"
        );
        require(
            ISpartan721A(spartan721AContract).mintsPerUser(to) + 1 <= ISpartan721A(spartan721AContract).mintingLimit(),
            "SPTN: Max NFT per address exceeded"
        );
        require(!ISpartan721A(spartan721AContract).mintId(mintId_), "SPTN: mint id already used");
        require(!mintId[mintId_], "SPTN: mint id already used");
        _merkleRoot > bytes32(0) && isAllowedToMint(proof_, mintId_);
        mintsPerUser[to] = ISpartan721A(spartan721AContract).mintsPerUser(to) + 1;
        mintId[mintId_] = true;

        ISpartan721A(spartan721AContract).adminMint(to, 1);

        spartan721AContract.transfer(msg.value);

        emit MintIdUsed(mintId_);
    }

    /**
     * @notice the public function validating addresses
     * @param proof_ hashes validating that a leaf exists inside merkle tree aka _merkleRoot
     * @param mintId_ Id sent from the db to check it this token number is minted or not
     **/
    function isAllowedToMint(bytes32[] memory proof_, bytes16 mintId_)
        internal
        view
        returns (bool)
    {
        require(
            MerkleProof.verify(
                proof_,
                _merkleRoot,
                keccak256(abi.encodePacked(mintId_))
            ),
            "SPTN: Please register before minting"
        );
        return true;
    }

    /**
     * @notice changes merkleRoot in case whitelist list updated
     * @param merkleRoot_ root of the Merkle tree
     **/

    function changeMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        require(
            merkleRoot_ != _merkleRoot,
            "SPTN: Merkle root cannot be same as previous"
        );
        _merkleRoot = merkleRoot_;
    }

    /**
     * @notice changes the minEthPrice in dollars
     * @param minEthPrice_  min price of eth
     **/
    function changeMinEthPrice(uint256 minEthPrice_) external onlyOwner {
        require(
            minEthPriceInDollars != minEthPrice_, 
            "SPTN: Min ETH Price should be different than the previous price"
        );
        minEthPriceInDollars = minEthPrice_;
    }

    /**
     * @notice changes the minEthPrice in dollars
     * @param maxEthPrice_  min price of eth
     **/
    function changeMaxEthPrice(uint256 maxEthPrice_) external onlyOwner {
        require(
            maxEthPriceInDollars != maxEthPrice_, 
            "SPTN: Max ETH Price should be different than the previous price"
        );
        maxEthPriceInDollars = maxEthPrice_;
    }

    /**
     * @notice changes the mint price of an already existing token ID
     * @param mintPrice_ new mint price of token
     **/
    function changeMintPriceOfToken(uint256 mintPrice_) external onlyOwner {
        require(
            mintPrice_ != mintPrice,
            "SPTN: Mint Price should be different than the previous price"
        );
        mintPrice = mintPrice_;
    }

}