// SPDX-License-Identifier: MIT

/**
*   @title Block Queens by Jeremy Cowart
*   @author Transient Labs
*   @notice ERC721 smart contract with single owner, Merkle allowlist, and royalty info per EIP 2981.
*   Block Queens Limited edition photographic ArtPhoto © 2022 Jeremy Cowart Photography, Inc. all rights reserved
*/

/*
 .----------------. .----------------. .----------------. .----------------. .----------------.                    
| .--------------. | .--------------. | .--------------. | .--------------. | .--------------. |                   
| |   ______     | | |   _____      | | |     ____     | | |     ______   | | |  ___  ____   | |                   
| |  |_   _ \    | | |  |_   _|     | | |   .'    `.   | | |   .' ___  |  | | | |_  ||_  _|  | |                   
| |    | |_) |   | | |    | |       | | |  /  .--.  \  | | |  / .'   \_|  | | |   | |_/ /    | |                   
| |    |  __'.   | | |    | |   _   | | |  | |    | |  | | |  | |         | | |   |  __'.    | |                   
| |   _| |__) |  | | |   _| |__/ |  | | |  \  `--'  /  | | |  \ `.___.'\  | | |  _| |  \ \_  | |                   
| |  |_______/   | | |  |________|  | | |   `.____.'   | | |   `._____.'  | | | |____||____| | |                   
| |              | | |              | | |              | | |              | | |              | |                   
| '--------------' | '--------------' | '--------------' | '--------------' | '--------------' |                   
 .----------------. .----------------. .----------------. .----------------. .-----------------..----------------. 
| .--------------. | .--------------. | .--------------. | .--------------. | .--------------. | .--------------. |
| |    ___       | | | _____  _____ | | |  _________   | | |  _________   | | | ____  _____  | | |    _______   | |
| |  .'   '.     | | ||_   _||_   _|| | | |_   ___  |  | | | |_   ___  |  | | ||_   \|_   _| | | |   /  ___  |  | |
| | /  .-.  \    | | |  | |    | |  | | |   | |_  \_|  | | |   | |_  \_|  | | |  |   \ | |   | | |  |  (__ \_|  | |
| | | |   | |    | | |  | '    ' |  | | |   |  _|  _   | | |   |  _|  _   | | |  | |\ \| |   | | |   '.___`-.   | |
| | \  `-'  \_   | | |   \ `--' /   | | |  _| |___/ |  | | |  _| |___/ |  | | | _| |_\   |_  | | |  |`\____) |  | |
| |  `.___.\__|  | | |    `.__.'    | | | |_________|  | | | |_________|  | | ||_____|\____| | | |  |_______.'  | |
| |              | | |              | | |              | | |              | | |              | | |              | |
| '--------------' | '--------------' | '--------------' | '--------------' | '--------------' | '--------------' |
 '----------------' '----------------' '----------------' '----------------' '----------------' '----------------' 
   ___                            __  ___         ______                  _         __    __       __     
  / _ \___ _    _____ _______ ___/ / / _ )__ __  /_  _________ ____  ___ (____ ___ / /_  / / ___ _/ /  ___
 / ___/ _ | |/|/ / -_/ __/ -_/ _  / / _  / // /   / / / __/ _ `/ _ \(_-</ / -_/ _ / __/ / /_/ _ `/ _ \(_-<
/_/   \___|__,__/\__/_/  \__/\_,_/ /____/\_, /   /_/ /_/  \_,_/_//_/___/_/\__/_//_\__/ /____\_,_/_.__/___/
                                        /___/                                                             
*/

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "MerkleProof.sol";
import "EIP2981.sol";

contract BlockQueens is EIP2981, ERC721, Ownable {

    bytes32 public merkleRoot;

    bool public preSaleMintOpen;
    bool public publicMintOpen;
    uint256 public presaleMintOpenTimestamp;
    uint256 public publicMintOpenTimestamp;
    mapping(address => uint256) public numMinted;
    uint256 public mintPrice = 0.22 ether;
    uint256 public mintAllowance;
    address payable public payoutAddr;
    bool public frozen;

    uint16[] public availableTokenIds;

    string private _baseTokenURI;

    modifier isNotFrozen {
        require(!frozen, "Error: Metadata is frozen");
        _;
    }

    /**
    *   @notice constructor for this contract
    *   @param root is the merkle root
    *   @param addr is the royalty payout address
    *   @param perc is the royalty payout percentage
    *   @param payout is the payout address
    */
    constructor(bytes32 root, address payout, address addr, uint256 perc) EIP2981(addr, perc) ERC721("Block Queens", "BQ") Ownable() {
        merkleRoot = root;
        payoutAddr = payable(payout);
        for (uint16 i = 0; i < 999; i++) {
            availableTokenIds.push(i+1);
        }
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
    *   @notice function to view total supply
    *   @return uint256 with supply
    */
    function totalSupply() public pure returns(uint256) {
        return 999;
    }

    /**
    *   @notice function to get remaining supply
    *   @return uint256
    */
    function getRemainingSupply() public view returns(uint256) {
        return availableTokenIds.length;
    }

    /**
    *   @notice function to get number minted per address
    */
    function getNumberMinted(address _address) public view returns (uint256) {
        return numMinted[_address];
    }

    /**
    *   @notice function to set the payout address
    *   @dev requires owner
    *   @param addr is the new payout address
    */
    function setPayoutAddress(address addr) public onlyOwner {
        payoutAddr = payable(addr);
    }

    /**
    *   @notice sets the baseURI for the ERC721 tokens
    *   @dev requires owner
    *   @param uri is the base URI set for each token
    */
    function setBaseURI(string memory uri) public onlyOwner isNotFrozen {
        _baseTokenURI = uri;
    }

    /**
    *   @notice override standard ERC721 base URI
    *   @dev doesn't require access control since it's internal
    *   @return string representing base URI
    */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    *   @notice function to freeze metadata
    *   @dev requires only owner
    */
    function freezeMetadata() public onlyOwner {
        frozen = true;
    }

    /**
    *   @notice function to set the presale mint status
    *   @dev sets the timestamp for presale mint to 60 minutes from when the function is called, if it hasn't been set yet
    *   @param status is the true/false flag for the presale mint status
    */
    function setPreSaleMintStatus(bool status) public onlyOwner {
        preSaleMintOpen = status;
        if (preSaleMintOpen && presaleMintOpenTimestamp == 0) {
            presaleMintOpenTimestamp = block.timestamp + 3600;
        }
        preSaleMintOpen ? mintAllowance = 1 : mintAllowance = 0;
    }

    /**
    *   @notice function to set the publi mint status
    *   @dev sets the timestamp for public mint to 60 minutes from when the function is called, if it hasn't been set yet
    *   @param status is the true/false flag for the public mint status
    */
    function setPublicMintStatus(bool status) public onlyOwner {
        publicMintOpen = status;
        if (publicMintOpen && publicMintOpenTimestamp == 0) {
            publicMintOpenTimestamp = block.timestamp + 3600;
        }
        publicMintOpen ? mintAllowance = 1 : mintAllowance = 0;
    }

    /**
    *   @notice function to update mint allowance
    *   @dev requires only
    *   @param allowance uint256 to set it to
    */
    function updateMintAllowance(uint256 allowance) public onlyOwner {
        mintAllowance = allowance;
    }

    /**
    *   @notice allowlist mint function
    *   @dev requires mint to be open
    *   @dev requires merkle proof to be valid, if in presale mint
    *   @dev requires mint price to be met
    *   @dev requires that the message sender hasn't already minted more than allowed at the time of the transaction
    *   @param merkleProof is the proof provided by the minting site
    */
    function mint(bytes32[] calldata merkleProof) public payable {
        require(availableTokenIds.length > 0, "All pieces have been minted");
        require(msg.value >= mintPrice, "Not enough ether");
        require(numMinted[msg.sender] < mintAllowance, "Reached mint limit");
        if (preSaleMintOpen && !publicMintOpen) {
            require(block.timestamp >= presaleMintOpenTimestamp, "Pre-sale mint not open yet");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Not on allowlist");
        }
        else if (publicMintOpen) {
            require(block.timestamp >= publicMintOpenTimestamp, "Public mint not open yet");
        }
        else {
            revert("Minting not open");
        }

        uint256 num = getRandomNum(availableTokenIds.length);
        _safeMint(msg.sender, uint256(availableTokenIds[num]));
        numMinted[msg.sender]++;

        availableTokenIds[num] = availableTokenIds[availableTokenIds.length - 1];
        availableTokenIds.pop();
    }

    /**
    *   @notice owner mint function
    *   @dev mints to the contract owner wallet
    *   @dev requires ownership of the contract
    */
    function ownerMint() public onlyOwner {
        require(availableTokenIds.length > 0, "All pieces have been minted");

        uint256 num = getRandomNum(availableTokenIds.length);
        _safeMint(msg.sender, uint256(availableTokenIds[num]));

        availableTokenIds[num] = availableTokenIds[availableTokenIds.length - 1];
        availableTokenIds.pop();
    }

    /**
    *   @notice function to get random token id to mint
    *   @param upper is the upper limit to get a number between (exculsive)
    */
    function getRandomNum(uint256 upper) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.coinbase, block.difficulty, msg.sender)));
        return random % upper;
    }

    /**
    *   @notice function to withdraw minting ether from the contract
    *   @dev requires owner to call
    */
    function withdrawEther() public onlyOwner {
        payoutAddr.transfer(address(this).balance);
    }

    /**
    *   @notice function to change the royalty recipient
    *   @dev requires owner
    *   @dev this is useful if an account gets compromised or anything like that
    *   @param _newRecipient is the new royalty recipient
    */
    function changeRoyaltyRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "Error: new recipient is the zero address");
        royaltyAddr = _newRecipient;
    }

    /**
    *   @notice function to change the royalty percentage
    *   @dev requires owner
    *   @dev this is useful if the amount was set improperly at contract creation. This can in fact happen... humans are prone to mistakes :) 
    *   @param _newPerc is the new royalty percentage, in basis points (out of 10,000)
    */
    function changeRoyaltyPercentage(uint256 _newPerc) public onlyOwner {
        require(_newPerc <= 10000, "Error: new percentage is greater than 10,0000");
        royaltyPerc = _newPerc;
    }

    /**
    *   @notice burn function for owners to use at their discretion
    *   @dev requires the msg sender to be the owner or an approved delegate
    *   @param tokenId is the token ID to burn
    */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not Approved or Owner");
        _burn(tokenId);
    }
}