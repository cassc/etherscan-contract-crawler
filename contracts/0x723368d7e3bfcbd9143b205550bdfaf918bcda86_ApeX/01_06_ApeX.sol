// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/ERC721.sol";


error NoTokensLeft();
error TooManyMintForTier();
error NotEnoughETH();
error NotOnWhitelist();
error DoesNotExist();
error WhitelistMintNotStarted();
error MintNotStarted();
error EmptyBalance();
error SwapNotOn();
error CantMintMoreThanOnce();
error AlreadyMintedWhitelist();


/// @title  ApeX contract 
/// @author @CrossChainLabs (https://canthedevsdosomething.com) 
contract ApeX is ERC721, Ownable {
    using Strings for uint256;
    

     /*///////////////////////////////////////////////////////////////
                                   AUTH
    //////////////////////////////////////////////////////////////*/

    address constant gnosisSafeAddress = 0xBC3eD63c8DB00B47471CfBD747632E24be5Cb5cd;
    address constant devWallet = 0x29c36265c63fE0C3d024b2E4d204b49deeFdD671;
    
    /// public key for whitelist
    address private signer;

    /// Payout wallets 
    address[14] private _contributorWallets;

    /// Contributor share split
    mapping(address => uint256) private _contributorShares;


    /*///////////////////////////////////////////////////////////////
                               MINT INFO
    //////////////////////////////////////////////////////////////*/

    uint256 constant public maxSupply = 4400 + 44;
    uint256 constant public mintPrice = 0.1 ether;
    bool public whitelistMintStarted = false;
    bool public mintStarted = false;
    bool public revealed = false;
    string public nonRevealedBaseURI;
    string public baseURI;

    /// @notice Maps address to bool if they have minted or not
    mapping(address => bool) public hasMinted;
    mapping(address => bool) public hasWhitelistMinted;

    /// @notice Maps 1:1 for address and free amount
    uint256[24] private _freeMintAmounts;
    address[24] private _freeMintWallets;

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwnerOrDev {
        require(msg.sender == gnosisSafeAddress || msg.sender == devWallet || msg.sender == owner());
        _;
    }

     modifier onlyTokenOwner(uint256 _tokenId) {
        require(msg.sender == ownerOf[_tokenId], "Only token owner can swap");
        _;
    }

    modifier amountLessThanTotalSupply (uint16 _amount) {
        if(totalSupply + _amount > maxSupply) revert NoTokensLeft();
        _;
    }

    modifier hasMintStarted {
        if(!mintStarted) revert MintNotStarted();
        _;
    }

    modifier isEnoughETH(uint16 amount) {
        if (msg.value < amount * mintPrice) revert NotEnoughETH();
        _;
    }

    modifier hasWalletMintedBefore() {
        if (hasMinted[msg.sender] == true) revert CantMintMoreThanOnce();
        _;
    }

    modifier hasWhitelistWalletMintedBefore(address _receiver) {
        if (hasWhitelistMinted[_receiver] == true) revert AlreadyMintedWhitelist();
        _;
    }

    modifier isMintingLessThanMaxMint(uint16 _amount) {
        require(_amount < 4, "Max mints per mint is 3");
        _;
    }


    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints 50 to the DAO Gnosis multisig wallet, sets the wallets, shares, airdrop free mints
    constructor (
        string memory _nonRevealedBaseURI, 
        uint256[14] memory shares, 
        address[14] memory wallets,
        address[24] memory freeMintAddresses,
        uint256[24] memory freeMintAmounts
        ) 
        ERC721("ApeX", "APEX") {
        
        nonRevealedBaseURI = _nonRevealedBaseURI;
        _freeMintWallets = freeMintAddresses;
        _freeMintAmounts = freeMintAmounts;
        signer = 0x53D5A3a2405705487d10CA08B61F07DEfCf7BcdD;


        /// @notice Initializes the contributor Amount
        for (uint256 i = 0; i < wallets.length; i++) {
            /// set the wallets
            _contributorWallets[i] = wallets[i];

            /// set the shares
            _contributorShares[_contributorWallets[i]] = shares[i];
        }
    }

    /// @dev Airdrop to the DAO multisig wallet and freeminters 
    function airdrop() external onlyOwner {
        /// loop through wallets array
        /// Hardcode to 24 since we know that's how long the list is
        for (uint256 i = 0; i < 24; i++) {
            
            uint256 numAllowed = _freeMintAmounts[i];
            address recipient = _freeMintWallets[i];
            /// loop through amount array
            for (uint256 j = 0; j < numAllowed; j++) {
                
                /// airdrop NFT to the freeminter
                _mint(recipient, totalSupply + 1);
            }
        }
    }


    /*///////////////////////////////////////////////////////////////
                            WHITELIST LOGIC
    //////////////////////////////////////////////////////////////*/

    function whitelistMint(uint16 amount, address _address, uint256 _numAllowed, bytes calldata _voucher) external payable 
        amountLessThanTotalSupply(amount) 
        isEnoughETH(amount) 
        hasWhitelistWalletMintedBefore(_address)
    {
        /// @notice Someone cant use someone elses voucher and mint for their own address
        require(msg.sender == _address, "Only the contributor can mint"); 
        if (!whitelistMintStarted) revert WhitelistMintNotStarted();
        require(amount <= _numAllowed, "Cannot mint more than allocated amount"); 
        
        /// confirm address and tier is coming from the correct source (frontend)
        bytes32 hash = keccak256(abi.encodePacked(_address, _numAllowed));
        if(_verifySignature(signer, hash, _voucher) == false) revert NotOnWhitelist();
        hasWhitelistMinted[_address] = true;

        unchecked {
            for (uint16 i = 0; i < amount; i++) {
                _mint(_address, totalSupply + 1);
            }
        }
    }

    function toggleWhitelistMint() public onlyOwnerOrDev {
        whitelistMintStarted = !whitelistMintStarted;
    }

    function toggleGeneralMint() public onlyOwnerOrDev {
        mintStarted = !mintStarted;
    }

    /*///////////////////////////////////////////////////////////////
                            MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function generalMint(uint16 amount) external payable 
        isMintingLessThanMaxMint(amount)
        amountLessThanTotalSupply(amount) 
        isEnoughETH(amount) 
        hasMintStarted 
        hasWalletMintedBefore
    {
        require(tx.origin == msg.sender, "No contract to contract calls");
        hasMinted[msg.sender] = true;

        unchecked {
            for (uint16 index = 0; index < amount; index++) {
                _mint(msg.sender, totalSupply + 1);
            }   
        }
    }

    /// @notice Withdraw to Gnosis multisig and associated wallets
    function withdraw() external onlyOwnerOrDev {
        if (address(this).balance == 0) revert EmptyBalance();
        uint256 currentBalance = address(this).balance;
        for (uint256 i=0; i < _contributorWallets.length; i++) {
            payable(_contributorWallets[i]).transfer(
                currentBalance * _contributorShares[_contributorWallets[i]] / 10000
            );
        }
    }


    /*///////////////////////////////////////////////////////////////
                                METADATA 
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        if (ownerOf[id] == address(0)) revert DoesNotExist();

        if (revealed == false) {
            return string(abi.encodePacked(nonRevealedBaseURI, id.toString()));
        }
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwnerOrDev {
        baseURI = _newBaseURI;
    }

    function reveal(string memory _baseUri) public onlyOwnerOrDev {
        setBaseURI(_baseUri);
        revealed = true;
    }

    /*///////////////////////////////////////////////////////////////
                            SIGNING LOGIC
    //////////////////////////////////////////////////////////////*/

    function setSigner(address _signer) external onlyOwnerOrDev {
        signer = _signer;
    }

    /// @dev Verify the frontend signature
    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) private pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }
}