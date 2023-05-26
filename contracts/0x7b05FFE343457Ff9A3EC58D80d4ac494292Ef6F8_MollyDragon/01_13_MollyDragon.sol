//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MollyDragon is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 222;
    uint256 public currentSupply = 0;

    uint256 public freeMinted;

    //Placeholders
    address private freeAddress = address(0x61ffbC142ABBE0262f0A4871Af01a16F044f712f);
    address private wallet = address(0x17Ed15ea125055E0234a0022F05a1d942D489877);

    string private baseURI;
    string private notRevealedUri = "ipfs://QmY3x55nPRJk79c1jgWzATfmoGR2FS3ceEezGNgNcvzo42";

    bool public revealed = false;
    bool public baseLocked = false;
    bool public marketOpened = false;
    bool public freeMintOpened = false;

    mapping(address => uint256) public freeMintAccess;
    mapping(address => uint256) public freeMintLog;

    constructor()
        ERC721("Molly Dragon", "MollyDragon")
    {
        transferOwnership(msg.sender);
        initFree();
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        payable( wallet ).transfer( _balance );
    }

    function setWallet(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function getFreeMintAmount( address _acc ) public view returns (uint256) {
        return freeMintAccess[ _acc ];
    }

    function getFreeMintLog( address _acc ) public view returns (uint256) {
        return freeMintLog[ _acc ];
    }

    function validateSignature( address _addr, bytes memory _s ) internal view returns (bool){
        bytes32 messageHash = keccak256(
            abi.encodePacked( address(this), msg.sender)
        );

        address signer = messageHash.toEthSignedMessageHash().recover(_s);

        if( _addr == signer ) {
            return true;
        } else {
            return false;
        }
    }

    //Batch minting
    function mintBatch(
        address to,
        uint256 baseId,
        uint256 number
    ) internal {

        for (uint256 i = 0; i < number; i++) {
            _safeMint(to, baseId + i);
        }

    }

    /**
        Claims tokens for free paying only gas fees
     */
    function freeMint(uint256 _amount, bytes calldata signature) external {
        //Free mint check
        require( 
            freeMintOpened, 
            "Free mint is not opened yet." 
        );

        //Check free mint signature
        require(
            validateSignature(
                freeAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        uint256 supply = currentSupply;
        uint256 allowedAmount = 1;

        if( freeMintAccess[ msg.sender ] > 0 ) {
            allowedAmount = freeMintAccess[ msg.sender ];
        } 

        require( 
            freeMintLog[ msg.sender ] + _amount <= allowedAmount, 
            "You dont have permision to free mint that amount." 
        );

        require(
            supply + _amount <= maxSupply,
            "MollyDragon: Mint too large, exceeding the collection supply"
        );


        freeMintLog[ msg.sender ] += _amount;
        freeMinted += _amount;
        currentSupply += _amount;

        mintBatch(msg.sender, supply, _amount);
    }

    function forceMint(uint256 number, address receiver) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "MollyDragon: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch( receiver, supply, number);
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "MollyDragon: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function openFreeMint() public onlyOwner {
        freeMintOpened = true;
    }
    
    function stopFreeMint() public onlyOwner {
        freeMintOpened = false;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require( baseLocked == false, "Base URI change has been disabled permanently");

        baseURI = _newBaseURI;
    }
    
    function setFreeMintAccess(address _acc, uint256 _am ) public onlyOwner {
        freeMintAccess[ _acc ] = _am;
    }

    //Lock base security - your nfts can never be changed.
    function lockBase() public onlyOwner {
        baseLocked = true;
    }

    //Once opened, it can not be closed again
    function openMarket() public onlyOwner {
        marketOpened = true;
    }

    // FACTORY
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),'.json'))
                : "";
    }

    function initFree() internal {
        freeMintAccess[ address(0x9723cC792c32dcA2744690f99103d095eA149E82) ] = 13;
        freeMintAccess[ address(0x08528a318b20e6213d1b848Baef381B3819c139b) ] =  8;
        freeMintAccess[ address(0xC15A3291144981E0Ae8b5444a299c201A0B08e87) ] =  6;
        freeMintAccess[ address(0xb36336BEB87613ffE60B28a6f94D8ab18973C10E) ] =  5;
        freeMintAccess[ address(0xC6Ac567b250b986acAE49A842Dad7865dA4be3a0) ] =  4;
        freeMintAccess[ address(0x4a9b4cea73531Ebbe64922639683574104e72E4E) ] =  4;
        freeMintAccess[ address(0xE718419c7DFF14Fc34AAbed3fcF4533BcF816960) ] =  4;
        freeMintAccess[ address(0xEa0bC5d9E7e7209Db6d154589EcB5A9eC834789B) ] =  3;
        freeMintAccess[ address(0x17Ed15ea125055E0234a0022F05a1d942D489877) ] =  3;
        freeMintAccess[ address(0x13d45928E955cCa32f4061E4D88b3D293FAB0256) ] =  3;
        freeMintAccess[ address(0x3C99046aA00B6e42a0Ec5858Bb2c9825cFf40A72) ] =  3;
        freeMintAccess[ address(0x919D316475DD4B894E2926Fe2c24B329d8Ade524) ] =  3;
        freeMintAccess[ address(0xb3CEd66d05495fdDD35e65CAa5Da7805755E51EF) ] =  2;
        freeMintAccess[ address(0xE0F6Bb10e17Ae2fEcD114d43603482fcEa5A9654) ] =  2;
        freeMintAccess[ address(0x0D57D42C7c784DA53325dA4d4287d39fcd9529de) ] =  2;
        freeMintAccess[ address(0x2132F5a587163540E0858c3258A6813d31fde053) ] =  2;
        freeMintAccess[ address(0x2388693c321842e2DcFdE252999E49f1d3EED79E) ] =  2;
        freeMintAccess[ address(0x5d0A692c1b83caE90a74bcD362d626A09b44FA98) ] =  2;
        freeMintAccess[ address(0xeE4B71C36d17b1c70E438F8204907C5e068229cc) ] =  2;
        freeMintAccess[ address(0x6B6065a8903906299552d6ED6358700AAe1c3a5C) ] =  2;
        freeMintAccess[ address(0xB91B6C1ccB75F93F06F3B5f41fECE1D691508146) ] =  2;
        freeMintAccess[ address(0x12C97D5933f2cFCAA64FdfcC45c89705c89Ca8f1) ] =  2;
        freeMintAccess[ address(0xE3506A409Fc03eD50D12143E98A8aDA2B8a40a5f) ] =  2;
        freeMintAccess[ address(0x562389B4B2b4c2123589800393D9c1c0051949C1) ] =  2;
        freeMintAccess[ address(0x481242c2d21289f5B7F92049a67979cb332571F0) ] =  2;
        freeMintAccess[ address(0x301daE850Cc3955275C878847C83FaC47F41a9Bd) ] =  2;
        freeMintAccess[ address(0x065735841E157d74Cd2D69A95d3E4C4003A76E28) ] =  2;
        freeMintAccess[ address(0x26b7e7a30E75A468cCcC8940D4C5829910aF5073) ] =  2;
        freeMintAccess[ address(0xaCff0c9930700e8aF89b4DA0360753941180C601) ] =  2;
        freeMintAccess[ address(0xacCB1e0eAa4d6bB3AB8268cFa8fB08d77F082655) ] =  2;
        freeMintAccess[ address(0x56E48cad4419A8a27DE6444f5839d85bCdBAfA27) ] =  2;
        freeMintAccess[ address(0x95bC2c07928A4AfC814c7A1b6036a3C684d5F7aF) ] =  2;
        freeMintAccess[ address(0x053e8f0723770206064b8B97A7746285fc175c71) ] =  2;
        freeMintAccess[ address(0xFC3eF7A7A6EedB8052F6CD9a61c798d794DE5C2C) ] =  2;
    }
 
}