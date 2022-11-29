/*
    Alejandro's Locomotoras
            ____
            |DD|____T_
            |_ |_____|<
              @[email protected]@-oo\
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SignedAllowance.sol";
import "./OperatorFilterer.sol";

/// @title Alejandro's Locomotoras
/// @author of the contract filio.eth (twitter.com/filmakarov)

interface IPrevCol { 
    function ownerOf(uint256 tokenId) external view returns (address);
    function MAX_ITEMS() external view returns (uint256); 
    function tokensOfOwner(address tokenOwner) external view returns (uint256[] memory);
}

contract LocomotorasA is ERC721A, Ownable, SignedAllowance, OperatorFilterer {  

    using Strings for uint256;

    event ChangeSent (address indexed receiver, uint256 indexed amount);

    /*///////////////////////////////////////////////////////////////
                                GENERAL STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_ITEMS = 2345;

    IPrevCol private blankTokenContract;

    string public baseURI;
    bool public saleState;
    bool public publicSaleState;

    uint256 public regularPrice = 35000000000000000; // 0.035 eth
    uint256 public cDAOPrice = 20000000000000000; // 0.02 eth
    uint256 public blankHoldersPrice = 25000000000000000; // 0.025 eth
    uint256 public vinylHoldersPrice = 10000000000000000; // 0.01 eth

    mapping (address => address) public replacedWallets;

    mapping (uint256 => uint256) public blankTokenClaimed;
    
    /*///////////////////////////////////////////////////////////////
                                INITIALISATION
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, string memory _myBase) 
        ERC721A(_name, _symbol) 
        OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) {
            baseURI = _myBase; 
    }

    /*///////////////////////////////////////////////////////////////
                        MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

        // allowlist mint and cdao mint thru snapshot
    function mint(address to, uint256 nonce, bytes memory signature) public payable {
        require (saleState, "Presale not active");
    
        //price is stored in the right-most 128 bits of the nonce
        uint256 price = (nonce << 128) >> 128;

        //qty is stored in the middle 64 bytes
        uint256 qty = ((nonce >> 128) << 192) >>192;

        require (msg.value >= price * qty, "mint(): Not Enough Eth");
 
        require(totalSupply() + qty <= MAX_ITEMS, ">MaxSupply");
        
        // this will throw if the allowance has already been used or is not valid
        _useAllowance(to, nonce, signature);

        _safeMint(to, qty); 
    }

    // Blank Token holders mint
    function blankHoldersMint (uint256[] calldata ownedTokens) external payable {
        require (saleState, "Presale not active");
        require (msg.value >= blankHoldersPrice * ownedTokens.length, "Not enough eth sent");

        address tokenOwner = checkReplacement(msg.sender);
        uint256 etherLeft = msg.value;
        uint256 qty = 0;

        for (uint256 i=0; i<ownedTokens.length; i++) {
            uint256 curTokenId = ownedTokens[i];
            if (blankTokenContract.ownerOf(curTokenId) == tokenOwner && blankTokenClaimed[curTokenId]==0 && curTokenId < blankTokenContract.MAX_ITEMS()) {
                etherLeft -= blankHoldersPrice; // can't go below zero because of a require above; in any case, no underflows with solidity 8.
                blankTokenClaimed[curTokenId] += 1;
                // we check every time coz maybe there are some skips, so we can't just check with total increase
                require(totalSupply() + 1 <= MAX_ITEMS, ">MaxSupply");
                qty++; 
            }
        }
        if (qty>0) {
            _safeMint(msg.sender, qty);
        }

        // return change if it has left
        if (etherLeft >= 0) {
            // since etherLeft is a local variable, there is no need to clear it,
            // even if someone decides to re-enter, etherLeft will be overwritten by the new msg.value
            // in fact there's no reason to re-enter here as you have to pay every time you call this method
            returnChange(etherLeft);
        }
    }

    // Vinyl holders mint (max 2 per every Vinyl token)
    function vinylHoldersMint (uint256[] calldata ownedTokens, uint256[] calldata usages) external payable {
        require (saleState, "Presale not active");
        require (ownedTokens.length == usages.length, "Array lenghts should match");

        // no msg.value check as it requires a for loop to calculate eth required for the tx
        // if not enough eth is provided, it will throw below

        address tokenOwner = checkReplacement(msg.sender);
        uint256 etherLeft = msg.value;
        uint256 qty = 0;

        for (uint256 i=0; i<ownedTokens.length; i++) {
            uint256 curTokenId = ownedTokens[i];
            uint256 tokensToMint = usages[i];
            if (blankTokenContract.ownerOf(curTokenId) == tokenOwner && curTokenId >= blankTokenContract.MAX_ITEMS()) {
                // explicitly revert here if usage is wrong - for more clarity
                require(blankTokenClaimed[curTokenId]+tokensToMint<=2, "Vinyl token mint limit exceeded");
                // will revert if goes below zero as no more underflows with solidity 8.
                etherLeft -= vinylHoldersPrice * tokensToMint;
                blankTokenClaimed[curTokenId] += tokensToMint;
                require(totalSupply() + tokensToMint <= MAX_ITEMS, ">MaxSupply");
                for (uint j=0; j<tokensToMint; j++) {
                    qty++;
                }
            }
        }
        if (qty>0) {
            _safeMint(msg.sender, qty); 
        }

        // return change if it has left
        if (etherLeft >= 0) {
            // since etherLeft is a local variable, there is no need to clear it,
            // even if someone decides to re-enter, etherLeft will be overwritten by the new msg.value
            // in fact there's no reason to re-enter here as you have to pay every time you call this method
            returnChange(etherLeft);
        }
    }

    // public mint, max 1 NFT per tx
    function publicMint() public payable {
        require (publicSaleState, "Public Sale not active");
    
        require(totalSupply() + 1 <= MAX_ITEMS, ">MaxSupply");
        require (msg.value >= regularPrice, "Not Enough Eth");
        _safeMint(msg.sender, 1);         
    }

    // adminMint
    function adminMint(address to, uint256 qty) public onlyOwner {
        require(totalSupply() + qty <= MAX_ITEMS, ">MaxSupply");
        _safeMint(to, qty); 
    }

    function returnChange(uint256 amount) private {
            (bool success, ) = (msg.sender).call{value: amount}("");
            if (!success) revert ("Recepient can not accept change");
            emit ChangeSent(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                       ROYALTIES PROTECTION
    //////////////////////////////////////////////////////////////*/

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable 
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*///////////////////////////////////////////////////////////////
                       WALLET MANAGEMENT FOR HOLDERS
    //////////////////////////////////////////////////////////////*/

    function replaceWallet(address newWallet) external {
        replacedWallets[newWallet] = msg.sender;
    }

    function checkReplacement(address currentWallet) public view returns (address) {
        if (replacedWallets[currentWallet] != address(0)) {
            return replacedWallets[currentWallet];
        } else {
            return currentWallet;
        }
    }

    /*///////////////////////////////////////////////////////////////
                       PUBLIC METADATA VIEWS
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Locomotoras: this token does not exist");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /*///////////////////////////////////////////////////////////////
                       VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Iterates over all the exisitng tokens and checks if they belong to the user
    /// This function uses very much resources.
    /// !!! NEVER USE this function with write transactions DIRECTLY. 
    /// Only read from it and then pass data to the write tx
    /// @param tokenOwner user to get tokens of
    /// @return the array of token IDs 
    function tokensOfOwner(address tokenOwner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(tokenOwner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 resultIndex = 0;
            uint256 NFTId;
            for (NFTId = 0; NFTId < _nextTokenId(); NFTId++) { 
                if (_exists(NFTId)) { 
                    if (ownerOf(NFTId) == tokenOwner) {
                        result[resultIndex] = NFTId;
                        resultIndex++;
                    }
                } 
            }     
            return result;
        }
    }

    // @dev interface compatibility 

    function nextTokenIndex() public view returns (uint256) {
        return _nextTokenId();
    }

    function getBlankTokenUsages(address owner) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory tokensIds = blankTokenContract.tokensOfOwner(owner);
        uint256[] memory usages = new uint256[](tokensIds.length);
        for (uint256 i=0; i<tokensIds.length; i++) {
            usages[i] = (blankTokenClaimed[tokensIds[i]]);
        }
        return(tokensIds, usages);
    }
    

    /*///////////////////////////////////////////////////////////////
                       ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function switchSaleState() public onlyOwner {
        saleState = !saleState;
    }

    function switchPublicSaleState() public onlyOwner {
        publicSaleState = !publicSaleState;
    }

    function setBlankContract(address _blankTokenAddress) public onlyOwner {
        blankTokenContract = IPrevCol(_blankTokenAddress);
    }

    /// @notice sets allowance signer, this can be used to revoke all unused allowances already out there
    /// @param newSigner the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    /// @notice Withdraws funds from the contract to msg.sender who is always the owner.
    /// No need to use reentrancy guard as receiver is always owner
    /// @param amt amount to withdraw in wei
    function withdraw(uint256 amt) public onlyOwner {
         address payable beneficiary = payable(owner());
        (bool success, ) = beneficiary.call{value: amt}("");
        if (!success) revert ("Withdrawal failed");
    } 
}

//   That's all, folks!