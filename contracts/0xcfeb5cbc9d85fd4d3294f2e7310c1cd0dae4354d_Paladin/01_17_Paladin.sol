// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "@franknft.eth/erc721-f/contracts/token/ERC721/ERC721FCOMMON.sol";
  
//      ▄▄▄▄▄▄▄    ▄▄▄     ▄▄         ┌▄▄─    ╔▄▄▄▄▄▄    ▄▄  ▄▄    φ▄      ╔▄▄▄▄▄▄   φ▄    ╔▄µ ]▄▄    ▄▄  φ▄    ▄▄M  ▄▄███▄
//      ██¬¬└╙██  ▐████    ██         ████    ╟█▌¬¬╙▀█▌  ██  ███▄  ██      ╟█▌¬¬╙██µ ██─   ╟█▌ ▐███   ██  ██─ ▓██¬  ▐█▌  ╙██
//      ██▄▄▄██▀ ┌██ ╙█▌   ██        ██─"██   ╟█▌    ██  ██  ██╙██ ██      ╟██▄▄▄██  ██─   ╟█▌ ▐█▌██▄ ██  ██████     ▀████▄╖
//      ██╙╙╙└   ███████▌  ██       ████████  ╟█▌   ]██  ██  ██ └████      ╟█▌╙╙╙─   ██─   ██▌ ▐█▌ ╙████  ██▀ ╙██µ  ▄▄   ╙██▌
//      ██      ██Γ    ██▄ ███████b▓█▌    ╙██ ╟██████▀¬  ██  ██   ███      ╟█▌       ╙███▄███  ▐█▌  └███  ██─   ██▌ ╙███▓███
//                                                                                      ¬¬¬                            ¬¬¬
//     
//     
//         
//                                                 ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                                                 ╠╠╠╠╠░░░░░░░░░░░░░░░░░░░░░░░░░
//                                                 ╠╠╠╠╠░░░░░░░░░░░░░░░░░░░░░░░░░
//                                            ░░░░░░░░░░░░░░░╠╠╠╠╠▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
//                                            ░░░░░░░░░░░░░░░╠╠╠╠╠▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░
//                                       ░░░░░░░░░░░░░░░▒▒▒▒▒     ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░
//                                       ░░░░░░░░░░░░░░░▒▒▒▒▒     ╠╠╠╠╠▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░
//                                  ≡≡≡≡≡░░░░░░░░░░▒▒▒▒▒`````     `````▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░≡≡≡≡≡
//                                  ░░░░░░░░░░░░░░░╠╠╠╠╠               ╠╠╠╠╠╠╠╠╠╠▒▒▒▒▒░░░░░░░░░░
//                                  ░░░░░░░░░░▄▄▄▄▄▄▄▄▄▄╓╓╓╓╓,,,,,,,,,,▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄░░░░░
//                                  ░░░░░╠╠╠╠╠█████████████████████████████████████████████╠╠╠╠╠
//                                  ░░░░░╠╠╠╠╠█████████████████████████████████████████████╠╠╠╠╠
//                             ░░░░░░░░░░█████               ███████████████               █████
//                             ░░░░░░░░░░█████               ███████████████               █████
//                             ░░░░░▒▒▒▒▒█████'''''''''''''''█████└└└└└█████'''''''''''''''█████
//                             ░░░░░╠╠╠╠╠█████               █████     █████               █████
//                             ░░░░░╠╠╠╠╠█████;;;;;;;;;;;;;;;█████     █████;;;;;;;;;;;;;;;█████
//                             ░░░░░╠╠╠╠╠█████░░░░░░░░░░░░░░░█████     █████░░░░░░░░░░░░░░░█████
//                             ░░░░░╠╠╠╠╠█████;;;;;;;;;;;;;;;█████     █████;;;;;;;;;;;;;;;█████
//                             ░░░░░╠╠╠╠╠░░░░░███████████████               ███████████████░░░░░
//                             ░░░░░╠╠╠╠╠░░░░░███████████████               ███████████████░░░░░
//                             ░░░░░▒░░░░░░░░░                    █████               │││││░░░░░
//                             ░░░░░▒▒▒▒▒░░░░░                    █████               ░░░░░░░░░░
//                             ░░░░░▒▒▒▒▒▒▒▒▒▒≥≥≥≥≥               ╙╙╙╙╙     ██████████████████████████████
//                             ░░░░░▒▒▒▒▒╠╠╠╠╠│││││                         ██████████████████████████████
//                             ░░░░░▒▒▒▒▒╠╠╠╠╠▄▄▄▄▄          ,,,,,,,,,,,,,,,▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█████▄▄▄▄▄
//                             ░░░░░▒▒▒▒▒╠╠╠╠╠█████          ╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣                         ╬╬╬╬╬█████
//                             ░░░░░▒▒▒▒▒╠╠╠╠╠█████          ╬╣╣╣╣╣╣╣╣╣╣╣╣╣╣                         ╬╬╬╬╬█████
//                             ░░░░░▒▒▒▒▒╠╠╠╠╠█████                         ██████████████████████████████
//                             ░░░░░▒▒▒▒▒╠╠╠╠╠█████                         ██████████████████████████████
//                             ░░░░░▒▒▒▒▒▓▓▓▓▓█████     █████               █████╬╬╬╬╬╬╬╬╬╬│││││¬¬¬¬¬¬¬¬¬¬
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████     █████               █████╬╬╬╬╬╠╠╠╠╠░░░░░
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████     ▀▀▀▀▀▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█████╬╬╬╬╬╠╠╠╠╠░░░░░
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████          ███████████████╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠░░░░░
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████          ▀▀▀▀▀██████████╣╣╣╣╣╬╬╬╬╬╠╠╠╠╠░░░░░
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████               █████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠░░░░░
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████               █████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠░░░░░
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████               █████╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠░░░░░
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████               █████╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠░░░░░
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████               █████╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠░░░░░
//                             ░░░░░▒▒▒▒▒╬╬╬╬╬█████               █████╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠░░░░░
//                             """"""""""╙╙╙╙╙▀▀▀▀▀               ▀▀▀▀▀╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙"""""

contract Paladin is ERC721FCOMMON {
    uint256 public constant MAX_TOKENS = 2321;
    uint256 public constant MAX_PURCHASE = 6;
    uint256 public tokenPrice = 0.0232 ether;
    bool public preSaleIsActive;
    bool public saleIsActive;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant TEAM = 0x66D243722019D30eaF476cd5Ef3C8dACD281514D;  
    mapping(address => uint256) private mintAmount;
    mapping(address => bool) private allowList1;
    mapping(address => bool) private allowList2;

    constructor() ERC721FCOMMON("Paladin Punks", "PUNKS") {
        setBaseTokenURI(
            "ipfs://QmWjMfCPgVcGQ8SKBKtauzMy1GyLg4y4sdxCGGWe2HWMPZ/"
        );
        _mint(FRANK, 101);     
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 101;
    }

    function allowAddresses1(address[] calldata _addresses) external onlyOwner {
        uint length = _addresses.length;
        for (uint i; i < length; ) {
            allowList1[_addresses[i]] = true;
            unchecked {
                i++;
            }
        }
    }

    function allowAddresses2(address[] calldata _addresses) external onlyOwner {
        uint length = _addresses.length;
        for (uint i; i < length; ) {
            allowList2[_addresses[i]] = true;
            unchecked {
                i++;
            }
        }
    }

    /**
     * Mint 1 to a array of wallets.
     */
    function airdrop(address[] calldata to) public onlyOwner {
        uint length = to.length;
        uint256 supply = _totalMinted();
        unchecked{
            for (uint i=0; i < length;) {
                _safeMint(to[i], supply + 101 + i);
                i++;
             }
        }

    }
    /**
     * Mint Tokens to a wallet.
     */
    function airdrop(address to, uint256 numberOfTokens) public onlyOwner {
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Reserve would exceed max supply of Tokens"
        );
        unchecked {
            for (uint256 i = 0; i < numberOfTokens; ) {
                _safeMint(to, supply + 101 + i);
                i++;
            }
        }
    }

    /**
     * Changes the state of preSaleIsactive from true to false and false to true
     */
    function flipPreSaleState() external onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    /**
     * Changes the state of saleIsActive from true to false and false to true
     * @dev If saleIsActive becomes `true` sets preSaleIsActive to `false`
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
        if (saleIsActive) {
            preSaleIsActive = false;
        }
    }

    /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 30
     */
    function mint(uint256 numberOfTokens)
        external
        payable
    {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");  
        require(msg.sender == tx.origin, "No Contracts allowed.");
        require(saleIsActive, "Sale NOT active yet");
        require(mintAmount[msg.sender]+numberOfTokens<MAX_PURCHASE,"Purchase would exceed max mint for walet");
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        unchecked {
            for (uint256 i; i < numberOfTokens; ) {
                _mint(msg.sender, supply +101+ i); // no need to use safeMint as we don't allow contracts.
                i++;
            }
        }
        mintAmount[msg.sender] = mintAmount[msg.sender]+numberOfTokens;
    }

    /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 30
     * @dev Uses MerkleProof to determine whether an address is allowed to mint during the pre-sale, non-mint name is due to hardhat being unable to handle function overloading
     */
    function mintPreSale(uint256 numberOfTokens)
        external
        payable
    {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(preSaleIsActive, "PreSale is not active yet");
        require(getPrice(msg.sender,numberOfTokens) <= msg.value, "Ether value sent is not correct");  
        uint8 max_purchase=0;
        if (allowList1[msg.sender]){
            max_purchase=4;
        } else if (allowList2[msg.sender]){
            max_purchase=3;
        }
        require(mintAmount[msg.sender]+numberOfTokens<max_purchase,"Purchase would exceed max mint for walet");
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        unchecked {
            for (uint256 i; i < numberOfTokens; ) {
                _safeMint(msg.sender, supply +101 + i);
                i++;
            }
        }
        mintAmount[msg.sender] = mintAmount[msg.sender]+numberOfTokens;
    }

    //////////////////////////////////
    // some methods for the website //
    //////////////////////////////////

    function canMint(address _address) external view returns(uint256){
        uint8 max_purchase=0;
        if(preSaleIsActive){
            if (allowList1[_address]){
               max_purchase=3;
            } else if (allowList2[_address]){
                max_purchase=2;
            }
            return max_purchase - mintAmount[_address];
        } else if (saleIsActive){
            return (MAX_PURCHASE -1) - mintAmount[_address];
        }
        return 0;
    }

    function getPrice(address _address, uint256 numberOfTokens) public view returns(uint256){
        if (allowList1[_address] && numberOfTokens==3 && preSaleIsActive){
            return 0.0464 ether;
        } else if ((allowList2[_address] || allowList1[_address]) && preSaleIsActive ){
            return 0.02 ether * numberOfTokens;
        }  else{
            return tokenPrice * numberOfTokens;
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _withdraw(FRANK,(balance * 10) / 100);
        _withdraw(TEAM, address(this).balance);
    }
}