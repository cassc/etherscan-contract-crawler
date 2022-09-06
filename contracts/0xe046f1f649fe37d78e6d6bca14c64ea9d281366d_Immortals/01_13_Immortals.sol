//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Immortals is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public MAX_FREE = 1111;
    uint256 public maxSupply = 1111;

    uint256 public currentSupply = 0;

    uint256 public freeMinted;

    //Placeholders
    address private freeAddress = address(0xe3a8333deD33DE0C0E2D7273075C5D4fd6B51C0B);
    address private wallet = address(0xC18008dA37F7E1E0544CbDEDB01209E5Bc0F5d1b);

    string private baseURI;
    string private notRevealedUri = "ipfs://QmXiD7XzC9m99EtZPdHq4gV1Xj6eyuTooQ1o6VYTWF8h6a";

    bool public revealed = false;
    bool public baseLocked = false;
    bool public freeMintOpened = false;

    mapping(address => uint256) public freeMintAccess;
    mapping(address => uint256) public freeMintLog;

    constructor()
        ERC721("The Immortals", "IMMORTALS")
    {
        transferOwnership(msg.sender);
        initFree();
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        
        payable( wallet ).transfer( _balance );
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
            "The Immortals: Mint too large, exceeding the maxSupply"
        );

        require(
            freeMinted + _amount <= MAX_FREE,
            "The Immortals: Mint too large, exceeding the free mint amount"
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
            "The Immortals: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch( receiver, supply, number);
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "The Immortals: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply;
        require(
            supply + addresses.length <= maxSupply,
            "The Immortals: You can't mint more than max supply"
        );

        currentSupply += addresses.length;

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], supply + i);
        }
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

    function setWallet(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }

    function setFreeMintAccess(address _acc, uint256 _am ) public onlyOwner {
        freeMintAccess[ _acc ] = _am;
    }

    //Lock base security - your nfts can never be changed.
    function lockBase() public onlyOwner {
        baseLocked = true;
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
        freeMintAccess[ address(0x906D966c5052072FEa8556194b79F61e8FF5a437) ] = 11;
        freeMintAccess[ address(0x5103E9f0D65f18464Ec8198a4cd0d47C6AB01Af9) ] = 6;
        freeMintAccess[ address(0x6E2B0832596BD499d3345D8D7E92dC53FBb0a9f9) ] = 6;
        freeMintAccess[ address(0x2A2794F7da0c5e27F0D0621AE47237E872bf62c2) ] = 6;
        freeMintAccess[ address(0x9A3dF2F66aef6bFbfB039476C92fD1fD408975de) ] = 6;
        freeMintAccess[ address(0x5849734d2E3adA23B64e12311Adfa6Bcd6FE687C) ] = 6;
        freeMintAccess[ address(0x402F9e4d2C24D2eb0544305a64D3e54309199662) ] = 5;
        freeMintAccess[ address(0x58c46AaFb723f1b8c51F8f3f37A31928EB4Bafb8) ] = 5;
        freeMintAccess[ address(0x8f85BDCbAD363bD67Bed3C1704B22f72e6679Eac) ] = 5;
        freeMintAccess[ address(0x968FC5388D52352c9aD67B3992D0B4b2D9D0c73C) ] = 4;
        freeMintAccess[ address(0x9e02A15Aa25Af3C76a92C53254Eac8f0Fc7046E9) ] = 4;
        freeMintAccess[ address(0xa29efBe892e9c76fD41F3848f811dB0BF0793DDe) ] = 4;
        freeMintAccess[ address(0xc17C0FD474a06b77e0E596A3f835D5bE97d6B531) ] = 4;
        freeMintAccess[ address(0xE6604f657b79582a055832694a542f38475DeCC5) ] = 4;
        freeMintAccess[ address(0x1C5EbE27c999EB7159de7F5BAF5350C66fe95607) ] = 4;
        freeMintAccess[ address(0x24Ee2846e0E6EBdBE0ffFFA1be269C405b7fD1d4) ] = 3;
        freeMintAccess[ address(0x2687B8f2762D557fBC8CFBb5a73aeE71fDd5C604) ] = 3;
        freeMintAccess[ address(0x52660b37441a8acDbD2146cF7dF0B8816a2B795e) ] = 3;
        freeMintAccess[ address(0x7224EC1b109f4BC32A61329815F329453D7e7BBF) ] = 3;
        freeMintAccess[ address(0x919D316475DD4B894E2926Fe2c24B329d8Ade524) ] = 3;
        freeMintAccess[ address(0xaD63d073e481335eDC49018D4996010894f1E3BD) ] = 5;
        freeMintAccess[ address(0xB3b5c600dF16B95FCf6F4A82283404Ba59226212) ] = 3;
        freeMintAccess[ address(0xb4253F5742de54391A3DCe67DCb077F987187d01) ] = 3;
        freeMintAccess[ address(0xb69b09B4aC684A3969D7DBB3b1d1FaB0740ac47F) ] = 4;
        freeMintAccess[ address(0xb7077b919F87f9bE1F307D42B3472E78C498134d) ] = 3;
        freeMintAccess[ address(0xCcC596132a67c67915493BCCC9edE57fBcf64944) ] = 3;
        freeMintAccess[ address(0xF636Cb531CB61f0CD7a9520ec05CF5771AE78c5a) ] = 3;
        freeMintAccess[ address(0x077FA8327Bfeb0D6b5CfA17560E8b825DA379b75) ] = 3;
        freeMintAccess[ address(0x0ACd6194761d97aa173f86c7d28a5723763C0b67) ] = 2;
        freeMintAccess[ address(0x1232002d77679F2208e4624706C6108e76F0CA03) ] = 2;
        freeMintAccess[ address(0x142875238256444be2243b01CBe613B0Fac3f64E) ] = 2;
        freeMintAccess[ address(0x242Ad38Af8Ab9e1056006472F25935379B3835F7) ] = 3;
        freeMintAccess[ address(0x25e0cE7cF653AE768A5B70d8d46d2745dFC98366) ] = 2;
        freeMintAccess[ address(0x27bad4cfF7F844C3743c0821199c40A9f8963EFB) ] = 2;
        freeMintAccess[ address(0x2bF02a25Eb96567C95a9443123d8fCA84CF75ca6) ] = 2;
        freeMintAccess[ address(0x315931efC6c5C890828745Fcf8e44bC2E4Da2E0C) ] = 2;
        freeMintAccess[ address(0x35C8C51135b2AF5727d990d9Ae3AD7564397bA50) ] = 2;
        freeMintAccess[ address(0x410d03Bc983E152BaBf9d133e547A02E2B8Eb09A) ] = 2;
        freeMintAccess[ address(0x501F0f47F3F9835EAC3F73223dC7D1adCd214BE1) ] = 3;
        freeMintAccess[ address(0x50B13f2F79Fa06Ab33f5eaf7ddea666499C36de2) ] = 3;
        freeMintAccess[ address(0x510bC11EB895d1c769EB0E18555f28836FB6e415) ] = 3;
        freeMintAccess[ address(0x57A3a65A83cb7Dae9658B0b69C7fb0E2771Ce38D) ] = 2;
        freeMintAccess[ address(0x58538dC6fe148E1252296A2Cfe1cc61bCB34104B) ] = 3;
        freeMintAccess[ address(0x61F59799298f52Ea38D3CbfDdb13796f3E5c8497) ] = 2;
        freeMintAccess[ address(0x644c1BE8457537eA67E4E43B6AFe610B3a275519) ] = 2;
        freeMintAccess[ address(0x6F1DA3eB78f52e008d487E942C84C9Aa70D6cbA1) ] = 2;
        freeMintAccess[ address(0x741495a2eccA8A9AdaF17bED68Be1BcAdD95dbF6) ] = 2;
        freeMintAccess[ address(0x7738e662c4385C995882B72Ac2149014dFA3C986) ] = 2;
        freeMintAccess[ address(0x7cbcAd18D6972A7d2380A8cf77a104ECB962dAc8) ] = 2;
        freeMintAccess[ address(0x7FdfE6C99683Bc7F423B7747A19F38ceB34d087e) ] = 3;
        freeMintAccess[ address(0x842cD65C4cBDBf46fB2Ca99e98b40bA4F8B7cf74) ] = 2;
        freeMintAccess[ address(0x97A10e823B72DC45792BC5C21Ee0F6F96eFD7f0A) ] = 2;
        freeMintAccess[ address(0x995A996d9f110f5955A2c44120701C52217A8AEc) ] = 3;
        freeMintAccess[ address(0x997A39c7DcbFD2EB2B409a5ed55f2a05093952A1) ] = 3;
        freeMintAccess[ address(0x99c49E96F663db4808A8262134D2a6801782ba1a) ] = 3;
        freeMintAccess[ address(0x9b6aFDE50FF47338Ef2A7af094553535E33f743E) ] = 4;
        freeMintAccess[ address(0x9C613623C2781D8df52089F7499414c3Ee02e095) ] = 2;
        freeMintAccess[ address(0xA130Cb2Af2aD6baE0bdA9CdD85dA86398752cCd2) ] = 3;
        freeMintAccess[ address(0xA590b33678B0A385e95Ee63276Cb2BDe80dDaC50) ] = 2;
        freeMintAccess[ address(0xAA8DF7Ed9c136071046806776B2271555e6A9423) ] = 3;
        freeMintAccess[ address(0xaCAb1Ae2C3bccCa4C2d4512c2B77bFdbB746C3b0) ] = 2;
        freeMintAccess[ address(0xb219e1986058870139335aad7A621bcA86D641E7) ] = 2;
        freeMintAccess[ address(0xbdfb0e3dF4f222EA9adaA70FB7837A4Ec687850c) ] = 2;
        freeMintAccess[ address(0xbF11349B63C396fc77F525ebb3C06d6A01deed84) ] = 2;
        freeMintAccess[ address(0xc0b7cd401fb05c1c730e2910cC79E8Ed8ec9EBbe) ] = 3;
        freeMintAccess[ address(0xc1000775A121133D7eBE8E952e4483401d1BF0f7) ] = 3;
        freeMintAccess[ address(0xc2b2568982707E9691DCE7BB23501071BC06f415) ] = 2;
        freeMintAccess[ address(0xc43160DFEB79727Ed3Bf745b9Cc8dAB39Dd6B896) ] = 2;
        freeMintAccess[ address(0xC5C911b8641277a721c97e9BBD4cFB81113B1c64) ] = 3;
        freeMintAccess[ address(0xC857B46Cee47b2e7661A9f337AcC496F9E6A3B76) ] = 2;
        freeMintAccess[ address(0xc9Fc73a660370898f61f50cb2e64104daaFdDFa4) ] = 2;
        freeMintAccess[ address(0xCC6041f3e1388a03d8b5bDD5A6350bC661C4EFb1) ] = 2;
        freeMintAccess[ address(0xd1c2c1eB4e3469F35769d7fb354fBD531b6e9c91) ] = 4;
        freeMintAccess[ address(0xdad836760e9eeBD3d71E2Be2B5293cc360086346) ] = 2;
        freeMintAccess[ address(0xE7c397f6ed7D3Be39024f1e79F6516cf7D8F1D50) ] = 2;
        freeMintAccess[ address(0xf6191643555Ed9f9932E1D318b457c5702254e48) ] = 2;
        freeMintAccess[ address(0xfBe93F2eaFAeF64d26DaC26DBDB07d5B0f7Bed35) ] = 2;
        freeMintAccess[ address(0xFBFf92e01498e37748bd63e085A9d7493028D798) ] = 2;
        freeMintAccess[ address(0xff5D847e8F5E0EB1cc36933e81E963A6319Bf523) ] = 2;
        freeMintAccess[ address(0xFFb760a5C1283E6eE2BeD28089417Bcb7E491202) ] = 3;
        freeMintAccess[ address(0x038BD57F518ADd55E74Cc9c4A75BB6862D42E20d) ] = 2;
        freeMintAccess[ address(0x200f8Cec9aD6EE6F6971e3611246D280530739e3) ] = 2;
        freeMintAccess[ address(0xe9bB334033e377E50038132556f285408B0478e0) ] = 2;
        freeMintAccess[ address(0xec6A3b23c4610c65954484a1c1072fc13E705F7D) ] = 2;
        freeMintAccess[ address(0xc504D3f9804dE19d9CB3CfcFfd0A7F7a4D002C14) ] = 2;
        freeMintAccess[ address(0xaB5C76aF29c67FE430190c5bBbDD6fd360304599) ] = 2;
        freeMintAccess[ address(0xa367b6bf139e574396a36319B2C3Bd0ceA47A5A0) ] = 2;
        freeMintAccess[ address(0x6fa290EcF1F63abe120259D00f13779a2f0382FF) ] = 2;
        freeMintAccess[ address(0x62D159f6F36d3CcCCd60d24d739180d2832bd722) ] = 2;
        freeMintAccess[ address(0x73Ce7096a0ce24177f3688F12255501719f98f9f) ] = 2;
        freeMintAccess[ address(0x7add69ebDB92EfD74E8E154987f244AD2cBBcF9d) ] = 2;
    }
}