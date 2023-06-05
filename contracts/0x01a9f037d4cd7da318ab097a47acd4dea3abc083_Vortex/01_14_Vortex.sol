// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//               . '@(@@@@@@@)@. (@@) `  .
//     .  @@'((@@@@@@@@@@@)@@@@@)@@@@@@@)@
//     @@(@@@@@@@@@@))@@@@@@@@@@@@@@@@)@@` .
//  @.((@@@@@@@)(@@@@@@@@@@@@@@))@\@@@@@@@@@)@@@
// (@@@@@@@@@@@@@@@@@@)@@@@@@@@@@@\\@@)@@@@@@@@)
//(@@@@@@@@)@@@@@@@@@@@@@(@@@@@@@@//@@@@@@@@@) `
// [email protected](@@@@)##&&&&&(@@@@@@@@)::_=(@\\@@@@)@@ .
//   @@`(@@)###&&&&&!!;;;;;;::[email protected]@\\@)@`@.
//   `   @@(@###&&&&!!;;;;;::[email protected]@\\@@
//      `  @.#####&&&!!;;;::=-_= [email protected] \
//            ####&&&!!;;::=_-
//             ###&&!!;;:-_=
//              ##&&!;::_=
//             ##&&!;:=
//            ##&&!:-
//           #&!;:-
//          #&!;=
//          #&!-
//           #&=
//            #&-
//            \\#/

/** @title Vortex */
contract Vortex is ERC721Enumerable, Ownable {
    string public contractState; // "presale_1", "presale_2" or "public_mint"
    bytes32 presale1State = keccak256(abi.encodePacked("presale_1"));
    bytes32 presale2State = keccak256(abi.encodePacked("presale_2"));
    bytes32 publicMintState = keccak256(abi.encodePacked("public_mint"));
    uint256 public constant mintPrice = 0.029 ether;
    uint256 public constant mintPriceDiscounted = 0.022 ether;
    uint256 public constant maxSupply = 1414;
    uint256 public constant reservedTokens = 21;
    uint256 public presaleGuaranteedTokens = 2;
    uint256 public presalePoolTokensClaimed = 0;
    uint256 public nWhitelisted;
    string private currentBaseURI;
    bytes32 private merkleRoot;
    address public presale1address = 0xC8100dD81e0D8D0901b7b5831e575b03E1489057; /// eternal fragments

    event Received(address, uint256);

    constructor() ERC721("Vortex", "VTX") {}

    /**
     * @dev Verify whether an address is on the whitelist
     * @param proof The required proof
     * @param leaf The leaf to verify, which has been created off-chain
     */
    function verify(bytes32[] memory proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /**
     * @dev Set the contract's state
     * @param _contractState The new desired contract state
     */
    function setContractState(string memory _contractState) public onlyOwner {
        contractState = _contractState;
    }

    /** @dev Update the base URI
     * @param baseURI_ New value of the base URI
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        currentBaseURI = baseURI_;
    }

    /** @dev Get the current base URI
     * @return currentBaseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return currentBaseURI;
    }

    /** @dev Sets the presale1 address
     * @param presale1Address_ the address
     */
    function setPresale1Address(address presale1Address_) public onlyOwner {
        presale1address = presale1Address_;
    }

    /** @dev Set the merkle root for address verification
     * @param merkleRoot_ the merkle root to set
     */
    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /** @dev Set number of tokens guaranteed to whitelisted addresses
     * @param qty the number of tokens to guarantee
     */
    function setPresaleGuaranteedTokens(uint256 qty) public onlyOwner {
        presaleGuaranteedTokens = qty;
    }

    /** @dev Set number of addresses whitelisted
     * @param qty the number of whitelisted addresses
     */
    function setNWhitelisted(uint256 qty) public onlyOwner {
        nWhitelisted = qty;
    }

    /**
     * @dev Check how many Eternal Fragments an address holds
     */
    function getExternalBalance(address contractAddress, address walletAddress)
        public
        view
        returns (uint256)
    {
        ERC721Enumerable token = ERC721Enumerable(contractAddress);
        return token.balanceOf(walletAddress);
    }

    /** @dev Mint in the presale
     * @param quantity The quantity of tokens to mint
     * @param proof The required proof
     */
    function presaleMint(uint256 quantity, bytes32[] memory proof)
        public
        payable
    {
        /// get the variables as comparable bytes
        bytes32 _contractState = keccak256(abi.encodePacked(contractState));
        /// check that one of the presale windows is active
        require(
            _contractState == presale1State || _contractState == presale2State,
            "Presale minting is not active"
        );

        // get the mint price
        uint256 _mintPrice = _contractState == presale1State
            ? mintPriceDiscounted
            : mintPrice;

        // check the txn value
        require(
            msg.value >= _mintPrice * quantity,
            "Insufficient value for presale mint"
        );

        // check that the required NFTs are held in the sender's wallet
        if (_contractState == presale1State) {
            // must hold an eternal fragment
            uint256 balance = getExternalBalance(presale1address, msg.sender);
            require(balance > 0, "Not holding any Eternal Fragments");
        }

        // get the sender's balance
        uint256 currentBalance = balanceOf(msg.sender);

        // calculate the total presale pool size
        uint256 presalePoolSize = maxSupply -
            (nWhitelisted * presaleGuaranteedTokens) -
            reservedTokens;

        // calculate the remaining presale pool based on the amt claimed so far
        uint256 remainingPresalePool = presalePoolSize -
            presalePoolTokensClaimed;

        // calculate the amount of guaranteed tokens available to the sender
        uint256 remainingGuaranteedTokens = currentBalance >
            presaleGuaranteedTokens
            ? 0
            : presaleGuaranteedTokens - currentBalance;

        // calculate the max number mintable in this txn
        uint256 mintableTokens = remainingGuaranteedTokens +
            remainingPresalePool;

        // check that the requested quantity is allowed
        require(mintableTokens >= quantity, "Presale supply is exhausted");

        /// check that the sender is on the whitelist
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(verify(proof, leaf), "Proof is not valid");

        // all checks have passed, mint the tokens
        mint(quantity, _contractState);
    }

    /** @dev Mint in the public sale
     * @param quantity The quantity of tokens to mint
     */
    function publicMint(uint256 quantity) public payable {
        bytes32 _contractState = keccak256(abi.encodePacked(contractState));
        require(
            _contractState == publicMintState,
            "Public minting is not active"
        );
        // check the txn value
        require(
            msg.value >= mintPrice * quantity,
            "Insufficient value for public mint"
        );
        mint(quantity, _contractState);
    }

    /** @dev Mints a token
     * @param quantity The quantity of tokens to mint
     * @param _contractState The contractState as bytes32
     */
    function mint(uint256 quantity, bytes32 _contractState) internal {
        /// Disallow transactions that would exceed the maxSupply
        require(totalSupply() + quantity <= maxSupply, "Supply is exhausted");

        // if it's presale, count the tokens minted that were guanranteed to the sender
        uint256 presalePoolToClaim = 0;
        if (
            _contractState == presale1State || _contractState == presale2State
        ) {
            // get the sender's balance
            uint256 currentBalance = balanceOf(msg.sender);

            // calculate how many of the guaranteed tokens are available to the sender
            // make guaranteedTokensToClaim non-negative
            // and avoid underflow
            uint256 guaranteedTokensToClaim = currentBalance >
                presaleGuaranteedTokens
                ? 0
                : presaleGuaranteedTokens - currentBalance;

            // calculate how much of the presale pool will be claimed
            // this is equal to any tokens beyond the 2 guaranteed
            presalePoolToClaim = quantity > guaranteedTokensToClaim
                ? quantity - guaranteedTokensToClaim
                : 0;
        }

        /// mint the requested quantity
        for (uint256 i = 0; i < quantity; i++) {
            if (presalePoolToClaim > 0) {
                // record that guaranteed tokens were claimed
                presalePoolTokensClaimed++;
                presalePoolToClaim--;
            }
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }

    /**
     * @dev Set some tokens aside for the creators
     */
    function reserveTokens() public onlyOwner {
        for (uint256 i = 0; i < reservedTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }

    /**
     * @dev Withdraw ether to owner's wallet
     */
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdraw failed");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}