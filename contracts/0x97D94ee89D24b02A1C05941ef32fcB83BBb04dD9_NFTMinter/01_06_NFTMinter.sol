// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SignedAllowance.sol";

interface INFT { 
    function mint(address to, uint256 qty) external;
    function sweepNFT(address sweeper, uint256 tokenId) external; 
    function unclaimedSupply() external view returns (uint256);
    function totalMinted() external view returns (uint256);
    function MAX_ITEMS() external view returns (uint256);
}

interface IWBMC { 
    function ownerOf(uint256 tokenId) external view returns (address); 
}

contract NFTMinter is Ownable, SignedAllowance{  

    /*///////////////////////////////////////////////////////////////
                            GENERAL STORAGE
    //////////////////////////////////////////////////////////////*/

    INFT private nftContract;
    IWBMC private wbmcContract;

    bool public presaleActive;
    
    bool public publicSaleActive;
    uint256 public publicSalePrice;  // 0 ETH
    uint256 public maxPerPublicMint = 1;

    mapping (uint256 => bool) public claimed;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _nftContract, address _wbmcContract) {
        setNFTContract(_nftContract);   
        wbmcContract = IWBMC(_wbmcContract);
    }

    /*///////////////////////////////////////////////////////////////
                        MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function presaleOrder(address to, uint256 nonce, bytes memory signature) public {
        require (presaleActive, "Presale not active");

        //qty is stored in the middle 64 bytes
        uint256 qty = uint256(uint64(nonce >> 128));

        // this will throw if the allowance has already been used or is not valid
        _useAllowance(to, nonce, signature);

        nftContract.mint(to, qty); 
    }

    function publicOrder(address to, uint256 qty) public payable {
        
        require(tx.origin == msg.sender, "Only EOAs allowed");
        require (publicSaleActive, "Public sale not active");
        require (qty <= maxPerPublicMint, ">Max per mint");
        require (msg.value >= publicSalePrice * qty, "Minter: Not Enough Eth");

        nftContract.mint(to, qty); 
    }

    function wbmcFreeMint(uint256[] calldata tokenIds) public {
        require (presaleActive, "Presale not active");
        
        uint256 qty = 0;
        
        for (uint256 i=0; i<tokenIds.length; i++) {
            uint256 curTokenId = tokenIds[i];
            if (wbmcContract.ownerOf(curTokenId) == msg.sender && !claimed[curTokenId]) {
                claimed[curTokenId] = true;
                qty++;
            }
        }
        nftContract.mint(msg.sender, qty); 
    }

    function adminMint(address to, uint256 qty) public onlyOwner {
        nftContract.mint(to, qty);
    }

    function donate() public payable {
        //  Thank you!
    }

    /*///////////////////////////////////////////////////////////////
                        VIEWS
    //////////////////////////////////////////////////////////////*/

    function unclaimedSupply() public view returns (uint256) {
        return nftContract.unclaimedSupply();
    }

    /*///////////////////////////////////////////////////////////////
                       ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setNFTContract(address _newNFT) public onlyOwner {
        nftContract = INFT(_newNFT);
    }

    function switchPresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function switchPublicSale() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setPublicSalePrice(uint256 _newPublicSalePrice) public onlyOwner {
        publicSalePrice = _newPublicSalePrice;
    }

    /// @notice sets allowance signer, this can be used to revoke all unused allowances already out there
    /// @param newSigner the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    function setMaxPerPublicMint(uint256 _newMaxPerMint) public onlyOwner {
        maxPerPublicMint = _newMaxPerMint;
    }

    /*///////////////////////////////////////////////////////////////
                       WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraws funds from the contract to msg.sender who is always the owner.
    /// @param amt amount to withdraw in wei
    function withdraw(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }

    /*///////////////////////////////////////////////////////////////
                       ERC721Receiver interface compatibility
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(
    address, 
    address, 
    uint256, 
    bytes calldata
    ) external pure returns(bytes4) {
        return bytes4(keccak256("I do not receive ERC721"));
    } 
}

//   That's all, folks!