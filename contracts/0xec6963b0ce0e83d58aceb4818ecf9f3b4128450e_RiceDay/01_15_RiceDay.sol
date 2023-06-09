pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RiceDay is Ownable, ERC721A, ReentrancyGuard {
    using ECDSA for bytes32;

    //total Supply
    uint256 public constant MAX_SUPPLY = 8866;

    //signer variables
    address private prepChefSigner;
    address private execChefSigner;

    //sale status variable
    enum SalePhase {
        Locked,
        PreSale,
        PublicSale
    }
    SalePhase public phase = SalePhase.Locked;

    //ricelist variables
    mapping(address => uint8) private _devList;
    mapping(address => uint256) private _prepAlreadyMint;
    mapping(address => uint256) private _execAlreadyMint;

    //base URI
    string baseURI;

    //price
    uint256 public priceRiceDay = 0.088 ether;

    constructor() ERC721A("RiceDay", "RICE", 3, 8866) {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //mint functions
    function publicSaleMint(uint256 numberOfTokens)
        external
        payable
        callerIsUser
    {
        require(
            phase == SalePhase.PublicSale,
            "Public sale minting is not active"
        );
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            priceRiceDay * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );
        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance <= 3, "cannot request that many"); //erc721 checks how many they can mint at a time
        _safeMint(msg.sender, numberOfTokens);
    }

    function prepChefMint(bytes calldata signature)
        external
        payable
        callerIsUser
    {
        require(phase == SalePhase.PreSale, "Presale minting not active");
        require(
            1 + totalSupply() <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(priceRiceDay <= msg.value, "Ether value sent is not correct");

        require(
            prepChefSigner ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature),
            "Signer address mismatch."
        );

        require(_prepAlreadyMint[msg.sender] == 0, "Already minted");

        _safeMint(msg.sender, 1);
        _prepAlreadyMint[msg.sender] = 1;
    }

    function execChefMint(uint256 numberOfTokens, bytes calldata signature)
        external
        payable
        callerIsUser
    {
        require(phase == SalePhase.PreSale, "Presale minting not active");
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(numberOfTokens <= 2, "Cannot purchase that many");

        require(
            execChefSigner ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature),
            "Signer address mismatch."
        );

        require(
            priceRiceDay * numberOfTokens <= msg.value,
            "Ether value sent is not correct"
        );

        require(_execAlreadyMint[msg.sender] + numberOfTokens <= 2, "Already minted");

        _safeMint(msg.sender, numberOfTokens);

        _execAlreadyMint[msg.sender] += numberOfTokens;
    }

    function devMint() external payable callerIsUser {
        require(_devList[msg.sender] > 0, "already claimed");
        uint8 allowedToMint = _devList[msg.sender];
        require(
            allowedToMint + totalSupply() <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        _safeMint(msg.sender, allowedToMint);
        _devList[msg.sender] = 0;
    }

    //changePhase
    function changePhase(SalePhase phase_) external onlyOwner {
        phase = phase_;
    }

    //set Price
    function setRiceDayPrice(uint256 newPrice) external onlyOwner {
        priceRiceDay = newPrice;
    }

    //set reveal
    function setRiceDayReveal(uint8 reveal) external onlyOwner {
        revealed = reveal;
    }

    //set signers
    function setSigners(address _prepChefSigner, address _execChefSigner)
        external
        onlyOwner
    {
        prepChefSigner = _prepChefSigner;
        execChefSigner = _execChefSigner;
    }

    // internal read base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //setting free mints
    function setDevMint(address[] calldata _addresses, uint8 amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _devList[_addresses[i]] = amount;
        }
    }

    //setting base uri
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    address public constant DEVELOPMENT_FUND_ADDRESS = 
        0x202e68E759282EAeD7673dB6E24889cf1b6F85b7; //Dev Fund
    address public constant OXY_ADDRESS =
        0xc73ab340a7d523EC7b1b71fE3d3494F94283b4B1; // Oxy
    address public constant FOUNDER_ADDRESS_1 =
        0x4D343925Df00700c4838112f22EbA49A0D4D07ae; // Nam
    address public constant FOUNDER_ADDRESS_2 =
        0x73248B42AB2cBb2008aE52fa7E14789CA40Cb279; // Giang
    address public constant COMMUNITYLEAD_ADDRESS =
        0x5774883C9dDAB26954d0D2CABeA2F97dbEe7CC1a; // Vi
    address public constant TECHLEAD_ADDRESS =
        0x19b260a039eDa8b896F4c7463445Fb94b4C86a85; // Moodi
    address public constant GENARTIST_ADDRESS =
        0xc54003e08b17f127196Eb3562bc2085BeD3332D5; // Trung
    address public constant RARITYARTIST_ADDRESS =
        0xa1B636D2e7D1C53Eba425e3e76B9BbEcf4D5Da56; // Hai

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(DEVELOPMENT_FUND_ADDRESS).transfer((balance * 5000) / 10000);
        payable(OXY_ADDRESS).transfer((balance * 1250) / 10000);
        payable(FOUNDER_ADDRESS_1).transfer((balance * 965) / 10000);
        payable(FOUNDER_ADDRESS_2).transfer((balance * 965) / 10000);
        payable(COMMUNITYLEAD_ADDRESS).transfer((balance * 450) / 10000);
        payable(TECHLEAD_ADDRESS).transfer((balance * 450) / 10000);
        payable(GENARTIST_ADDRESS).transfer((balance * 600) / 10000);
        payable(RARITYARTIST_ADDRESS).transfer((balance * 320) / 10000);
    }
}