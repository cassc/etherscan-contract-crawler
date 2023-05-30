// SPDX-License-Identifier: MIT

/**
*   @title Squiggle Game
*   @author Transient Labs
*/

/*                                                                                                  
 _______ _______ _______ _______ _______ _______ _______ _______     _______ _______ _______ _______    
|\     /|\     /|\     /|\     /|\     /|\     /|\     /|\     /|   |\     /|\     /|\     /|\     /|   
| +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ |   | +---+ | +---+ | +---+ | +---+ |   
| |   | | |   | | |   | | |   | | |   | | |   | | |   | | |   | |   | |   | | |   | | |   | | |   | |   
| |S  | | |q  | | |u  | | |i  | | |g  | | |g  | | |l  | | |e  | |   | |G  | | |a  | | |m  | | |e  | |   
| +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ | +---+ |   | +---+ | +---+ | +---+ | +---+ |   
|/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|/_____\|   |/_____\|/_____\|/_____\|/_____\|   
                                                                                                        
*/

pragma solidity ^0.8.9;

import "ERC721.sol";
import "Ownable.sol";
import "MerkleProof.sol";
import "Base64.sol";
import "ECDSA.sol";
import "Strings.sol";
import "EIP2981.sol";

contract SquiggleGame is ERC721, EIP2981, Ownable {
    using Strings for uint256;

    struct TokenDetails {
        bool usedAsMintPass;
        bool scoreLocked;
        uint64 score;
        uint256 cooldownTimer;
    }

    bool public preSaleMintOpen;
    bool public publicMintOpen;
    bool public scoreLockingOpen;
    uint256 public counter;
    uint256 public totalSupply;
    uint256 public mintAllowance = 1;
    uint256 public mintPrice;
    bytes32 public merkleRoot;
    address payable public payoutAddr;
    address public scoreValidatorAddr;
    address public mintPassRedeemerAddr;
    string internal gameURI;
    string internal coverURI;
    mapping(address => uint64) internal numMinted;
    mapping(uint256 => TokenDetails) internal tokenDetails;

    event ScoreLocked(address indexed from, uint256 indexed tokenId, uint64 indexed score);

    modifier isRedeemer {
        require(msg.sender == mintPassRedeemerAddr, "Error: caller is not mint pass redeemer");
        _;
    }

    /**
    *   @notice constructor for this contract
    *   @param _supply is the total supply
    *   @param _payout is the payout address
    *   @param _royalty is the royalty payout address
    *   @param _perc is the royalty payout percentage
    */
    constructor(uint256 _supply, address _payout, address _royalty, uint256 _perc) ERC721("Squiggle Game", "SG") EIP2981(_royalty, _perc) Ownable() {
        totalSupply = _supply;
        payoutAddr = payable(_payout);
    }

    /**
    *   @notice function to set the payout address
    *   @dev requires owner
    *   @param _addr is the new payout address
    */
    function setPayoutAddress(address _addr) external onlyOwner {
        payoutAddr = payable(_addr);
    }

    /**
    *   @notice function to set the score validator address
    *   @dev requires owner
    *   @param _addr is the new score validator address
    */
    function setScoreValidatorAddress(address _addr) external onlyOwner {
        scoreValidatorAddr = _addr;
    }

    /**
    *   @notice function to set the mint pass redeemer address
    *   @dev requires owner
    *   @param _addr is the new redeemer address
    */
    function setMintPassRedeemerAddress(address _addr) external onlyOwner {
        mintPassRedeemerAddr = _addr;
    }

    /**
    *   @notice sets the uri for the game
    *   @dev requires owner
    *   @param _uri is the game script uri
    */
    function setGameURI(string memory _uri) external onlyOwner {
        gameURI = _uri;
    }

    /**
    *   @notice sets the base uri for the cover image
    *   @dev requires owner
    *   @param _uri is the base cover uri
    */
    function setCoverURI(string memory _uri) external onlyOwner {
        coverURI = _uri;
    }

    /**
    *   @notice function to set allowlist and mint price
    *   @dev only owner
    *   @param _merkleRoot is the new merkleRoot
    *   @param _price is the new mint price
    */
    function setPresaleData(bytes32 _merkleRoot, uint256 _price) external onlyOwner {
        merkleRoot = _merkleRoot;
        mintPrice = _price;
    }

    /**
    *   @notice function to open the presale
    */
    function openPreSale() external onlyOwner {
        publicMintOpen = false;
        preSaleMintOpen = true;
    }

    /**
    *   @notice function to open the public mint
    */
    function openPublicMint() external onlyOwner {
        preSaleMintOpen = false;
        publicMintOpen = true;
    }

    /**
    *   @notice function to close both mints
    *   @dev requires owner of the contract
    */
    function closeMints() external onlyOwner {
        preSaleMintOpen = false;
        publicMintOpen = false;
    }

    /**
    *   @notice function to update mint allowance
    *   @dev requires only owner
    *   @param _allowance uint256 to set it to
    */
    function setMintAllowance(uint256 _allowance) external onlyOwner {
        mintAllowance = _allowance;
    }

    /**
    *   @notice allowlist mint function
    *   @dev requires mint to be open
    *   @dev requires merkle proof to be valid, if in presale mint
    *   @dev requires mint price to be met
    *   @dev requires that the message sender hasn't already minted more than allowed at the time of the transaction
    *   @param _merkleProof is the proof provided by the minting site
    */
    function mint(bytes32[] calldata _merkleProof) external payable {
        require(counter < totalSupply, "All pieces have been minted");
        require(numMinted[msg.sender] < mintAllowance, "Reached mint limit");
        require(msg.value >= mintPrice, "Not enough ether");
        if (preSaleMintOpen) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Not on allowlist");
        }
        else if (!publicMintOpen) {
            revert("Mint not open");
        }

        numMinted[msg.sender]++;
        counter++;
        _safeMint(msg.sender, counter);
    }

    /**
    *   @notice owner mint function
    *   @dev mints to the contract owner wallet
    *   @dev requires ownership of the contract
    *   @param _numToMint is the number to mint
    */
    function ownerMint(uint256 _numToMint) external onlyOwner {
        require(counter + _numToMint <= totalSupply, "All pieces have been minted");
        for (uint256 i; i < _numToMint; i++) {
            counter++;
            _safeMint(payoutAddr, counter);
        }
    }

    /**
    *   @notice function to flip score locking
    *   @dev requires owner
    */
    function flipScoreLocking() external onlyOwner {
        scoreLockingOpen = !scoreLockingOpen;
    }

    /**
    *   @notice function to lock score to the blockchain
    *   @dev caller must be the owner of the token
    *   @param _tokenId is the token id
    *   @param _score is the score
    *   @param _sig is the signed message containing the score
    */
    function lockScore(uint256 _tokenId, uint64 _score, bytes calldata _sig) external {
        require(_exists(_tokenId), "Not a valid token id");
        require(scoreLockingOpen, "Score locking is not open yet");
        require(tokenDetails[_tokenId].scoreLocked == false, "Score already has been locked");
        require(tokenDetails[_tokenId].usedAsMintPass == false, "Token has been used as a mint pass already");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Message sender is not the owner of the token");
        bytes32 msgHash = generateMessageHash(_tokenId, _score);
        address resolvedAddr = ECDSA.recover(msgHash, _sig);
        require(resolvedAddr == scoreValidatorAddr, "Resolved address not the same as the validator address");

        tokenDetails[_tokenId].score = _score;
        tokenDetails[_tokenId].scoreLocked = true;
        tokenDetails[_tokenId].cooldownTimer = block.timestamp + 5 hours;

        emit ScoreLocked(msg.sender, _tokenId, _score);
    }

    /**
    *   @notice function to use the token as a mint pass
    *   @dev can only be called by the redeemer contract address
    *   @param _tokenId is the token id
    *   @param _addr is the caller from the redeemer contract
    */
    function useAsMintPass(uint256 _tokenId, address _addr) external isRedeemer {
        require(_exists(_tokenId), "Not a valid token id");
        require(tokenDetails[_tokenId].usedAsMintPass == false, "Already used as mint pass");
        require(_isApprovedOrOwner(_addr, _tokenId), "Address is not the owner of the token");

        tokenDetails[_tokenId].usedAsMintPass = true;
        tokenDetails[_tokenId].cooldownTimer = block.timestamp + 5 hours;
    }

    /**
    *   @notice function to withdraw minting ether from the contract
    *   @dev requires owner to call
    */
    function withdrawEther() external onlyOwner {
        payoutAddr.transfer(address(this).balance);
    }

    /**
    *   @notice function to change the royalty recipient
    *   @dev requires owner
    *   @dev this is useful if an account gets compromised or anything like that
    *   @param _newRecipient is the new royalty recipient
    */
    function changeRoyaltyRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Error: new recipient is the zero address");
        royaltyAddr = _newRecipient;
    }

    /**
    *   @notice function to change the royalty percentage
    *   @dev requires owner
    *   @dev this is useful if the amount was set improperly at contract creation. This can in fact happen... humans are prone to mistakes :) 
    *   @param _newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function changeRoyaltyPercentage(uint256 _newPerc) external onlyOwner {
        require(_newPerc <= 10000, "Error: new percentage is greater than 10,000");
        royaltyPerc = _newPerc;
    }

    /**
    *   @notice function to get remaining supply
    *   @return uint256
    */
    function getRemainingSupply() external view returns(uint256) {
        return totalSupply - counter;
    }

    /**
    *   @notice function to get number minted per address
    */
    function getNumberMinted(address _address) external view returns (uint64) {
        return numMinted[_address];
    }

    /**
    *   @notice function to get whether the token has been used as a mint pass
    *   @dev doesn't throw if token id doesn't exist
    *   @param _tokenId is the token id to look up
    *   @return bool showing if it has
    */
    function getIfUsedAsMintPass(uint256 _tokenId) external view returns (bool) {
        return tokenDetails[_tokenId].usedAsMintPass;
    }

    /**
    *   @notice function to get whether the token has a score locked
    *   @dev doesn't throw if token id doesn't exist
    *   @param _tokenId is the token id to look up
    *   @return bool showing if it has been locked or not
    */
    function getIfScoreLocked(uint256 _tokenId) external view returns (bool) {
        return tokenDetails[_tokenId].scoreLocked;
    }

    /**
    *   @notice function to get the token score
    *   @param _tokenId is the token id to look up
    *   @return uint64 showing the score
    */
    function getScore(uint256 _tokenId) external view returns (uint64) {
        return tokenDetails[_tokenId].score;
    }

    /**
    *   @notice overrides EIP721 and EIP2981 supportsInterface function
    *   @param interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    *   @return a boolean saying if this contract supports the interface or not
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, EIP2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    /**
    *   @notice override standard ERC721 tokenURI
    *   @param tokenId is the token id
    *   @return base64 encoded json representing token uri
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory state = scoreLockingOpen ? "1" : "0";
        string memory locked = "No";
        string memory used = "No";
        if (tokenDetails[tokenId].scoreLocked) {
            state = "2";
            locked = "Yes";
        }
        if (tokenDetails[tokenId].usedAsMintPass) {
            state = "3";
            used = "Yes";
        }
        string memory cover = string(abi.encodePacked(coverURI, "/", state));
        string memory html = string(abi.encodePacked(
            gameURI, "?tokenId=", tokenId.toString(), "&state=", state));
        string memory traits = string(abi.encodePacked(
            '{"trait_type":"Score Locked","value":"', locked, '"},',
            '{"trait_type":"Score","value":"', uint256(tokenDetails[tokenId].score).toString(), '"},'
            '{"trait_type":"Used As Mint Pass","value":"', used, '"}'
        ));
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(abi.encodePacked(
                    '{"name":"Squiggle Game #',
                    tokenId.toString(), '",',
                    '"description":"LIT Squiggle Game is designed especially for mobile. Right from your Opensea account. You can use your finger on your screen to navigate the Squiggle and master the game. Catch as many flames as you can without hitting the walls or bumping into any black squares. Each flame is worth 10 points. The Rules, FAQ and how to participate in The LIT Squiggle Game Challenge can be found by the Squiggle Game webApp: [https://squigglegame.wtf](https://squigglegame.wtf)",',
                    '"attributes": [', traits, '],',
                    '"image":"', cover, '",',
                    '"animation_url":"', html, '"}'
                )))
            )
        );
    }

    /**
    *   @notice function to create message hash for score writing purposes
    */
    function generateMessageHash(uint256 _tokenId, uint64 _score) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n40", _tokenId, _score));
    }

    /**
    *   @notice function to act as a cooldown timer after a score has been locked or the piece has been used as a mint pass
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(block.timestamp >= tokenDetails[tokenId].cooldownTimer, "Error: token properties were recently changed");
    }
}