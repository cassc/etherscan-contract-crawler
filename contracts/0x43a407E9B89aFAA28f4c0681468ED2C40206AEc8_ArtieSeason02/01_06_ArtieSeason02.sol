// SPDX-License-Identifier: MIT
// To view Artie’s license agreement, please visit artie.com/general-terms
/*****************************************************************************************************************************************************
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@                &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@        @@        [email protected]@@@@@@@@@@@@@@         @         @@                       @@,        @@@@@@@@@,                  @@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@        @@@@         @@@@@@@@@@@@@@                   @@                       @@,        @@@@@@@                        @@@@@@@@@@@@
 @@@@@@@@@@@@@@@        @@@@@@         @@@@@@@@@@@@@                   @@                       @@,        @@@@@          (@@@@@@          @@@@@@@@@@@
 @@@@@@@@@@@@@(        @@@@@@@@         @@@@@@@@@@@@          @@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@@         @@@@@@@@@@@         @@@@@@@@@@
 @@@@@@@@@@@@         @@@@@@@@@@         @@@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@&%         @@@@@@@@@
 @@@@@@@@@@@                              @@@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@@                                @@@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@                               @@@@@@@@@
 @@@@@@@@@                                  @@@@@@@@         @@@@@@@@@@@@@@@@@@         @@@@@@@@@@,        @@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@                                    @@@@@@@         @@@@@@@@@@@@@@@@@@          @@@@@@@@@.        @@@@         @@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
 @@@@@@@         @@@@@@@@@@@@@@@@@@@@         @@@@@@         @@@@@@@@@@@@@@@@@@                 @@,        @@@@@            @@@@@         @@@@@@@@@@@@
 @@@@@@         @@@@@@@@@@@@@@@@@@@@@@         @@@@@         @@@@@@@@@@@@@@@@@@@                @@,        @@@@@@@                         @@@@@@@@@@@
 @@@@@         @@@@@@@@@@@@@@@@@@@@@@@@         @@@@         @@@@@@@@@@@@@@@@@@@@               @@,        @@@@@@@@@@                   @@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     (@@@@@@@@@@@@@@@@@@@@
 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*****************************************************************************************************************************************************/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IDispensary {
    function safeMint(address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBurn(address to, uint256 tokenID, uint256 amount) external;
}

interface IArtie {
    function safeMint(address to, uint256 tokenId) external;
}


contract ArtieSeason02 is Ownable {
    using ECDSA for bytes32;

    uint256 public constant PURCHASE_LIMIT = 5;

    address public signingAddress;
    mapping(bytes16 => bool) public usedNonces;
    mapping(uint256 => uint256) public freeMintTokenIds;
    mapping(uint256 => uint256) public mintTokenIds;

    uint256 public immutable MAX_TOKEN;

    uint256 public constant price = 0.15 ether;

    uint256 public constant grannyDiskPrice = 0.1 ether;

    uint256 public current;

    bool public saleStarted;

    bool public allowGrannyMint;

    IArtie public immutable artie;

    address payable public withdrawalAddress;

    IDispensary public immutable dispensary;

    event Season02Mint(
        address to,
        uint256 amount,
        uint256 current
    );

    constructor(address payable artieCharAddress, address payable withdrawAddress, address signer, address _dispensary,
        uint256 _current, uint256 _max_token,
        uint256[] memory _freeMintTokenIds, uint256[] memory _freeMintBurnedTokenIds, uint256[] memory _mintTokenIds, uint256[] memory _mintBurnedTokenIds) Ownable() {
        require(_freeMintTokenIds.length == _freeMintBurnedTokenIds.length, "Array length mismatch freeMint");
        require(_mintTokenIds.length == _mintBurnedTokenIds.length, "Array length mismatch mint");
        artie = IArtie(artieCharAddress);
        current = _current;
        MAX_TOKEN = _max_token;
        withdrawalAddress = withdrawAddress;
        signingAddress = signer;
        dispensary = IDispensary(_dispensary);
        for (uint256 i = 0; i < _freeMintTokenIds.length; i++) {
            freeMintTokenIds[_freeMintTokenIds[i]] = _freeMintBurnedTokenIds[i];
        }
        for (uint256 i = 0; i < _mintTokenIds.length; i++) {
            mintTokenIds[_mintTokenIds[i]] = _mintBurnedTokenIds[i];
        }
    }

    modifier saleIsOpen() {
        require(saleStarted, "SALE_NOT_STARTED");
        _;
    }

    modifier onlyWallets() {
        require(tx.origin == msg.sender, "NO_CONTRACTS_ALLOWED");
        _;
    }

    modifier grannyMintEnabled() {
        require(allowGrannyMint, "GRANNY_MINTING_DISABLED");
        _;
    }

    function hashRequest(bytes16 nonce, address to, uint256 numRequested, uint256 transactionNumber) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(nonce, to, numRequested, transactionNumber));
    }

    function _verify(bytes32 hash, bytes memory signature, address validator) internal pure returns (bool) {
        return hash.recover(signature) == validator;
    }

    function mint(bytes16 nonce, uint256 numberOfTokens, uint256 transactionNumber, bytes memory signature) external payable saleIsOpen onlyWallets{
        require(_verify(hashRequest(nonce, msg.sender, numberOfTokens, transactionNumber).toEthSignedMessageHash(), signature, signingAddress), "NO DIRECT MINTING ALLOWED");
        require(!usedNonces[nonce], "NONCE USED");

        require(price * numberOfTokens == msg.value, "INCORRECT_ETH_AMOUNT");
        require(current + numberOfTokens <= MAX_TOKEN, "MAX_TOKENS_EXCEEDED");
        require(numberOfTokens <= PURCHASE_LIMIT, "PURCHASE_LIMIT_EXCEEDED");

        usedNonces[nonce] = true;
        uint256 tokenId = current;
        for (uint256 i = 0; i < numberOfTokens; i++) {
            tokenId++;
            artie.safeMint(msg.sender, tokenId);
        }
        current = tokenId;
        emit Season02Mint(msg.sender, numberOfTokens, current);
    }

    // ----- Sale functions --------


    function startSale() external onlyOwner {
        saleStarted = true;
    }

    function stopSale() external onlyOwner {
        saleStarted = false;
    }

    function enableGrannyMint() external onlyOwner {
        allowGrannyMint = true;
    }

    function disableGrannyMint() external onlyOwner {
        allowGrannyMint = false;
    }


    // ------ Withdrawal functions ------------------ 

    function setWithdrawalAddress(address payable givenWithdrawalAddress) external onlyOwner {
        withdrawalAddress = givenWithdrawalAddress;
    }

    function withdrawEth() external onlyOwner {
        require(withdrawalAddress != address(0), 'WITHDRAWAL_ADDRESS_ZERO');
        Address.sendValue(withdrawalAddress, address(this).balance);
    }


    // ------ Signer Address Modifier --------------

    function setSignerAddress(address signer) external onlyOwner {
        signingAddress = signer;
    }

    // ----- Granny Minting Functions ------------

    function freeMintFromGranny(uint256 amount, uint256 tokenId) public grannyMintEnabled onlyWallets {
        require(amount > 0, "Must mint at least one token");
        require(current + amount <= MAX_TOKEN, "MAX_TOKENS_EXCEEDED");
        uint256 usedTokenId = freeMintTokenIds[tokenId];
        require(usedTokenId != 0, "TokenId is not a valid burnable tokenId for free minting");
        //Burn the Granny Token; will only succeed if the msg.sender has a sufficient amount of tokenId in their wallet
        dispensary.safeBurn(msg.sender, tokenId, amount);
        //Mint the Used version of the Granny token to the sender's wallet
        dispensary.safeMint(msg.sender, usedTokenId, amount, '');
        //Mint from Artie
        uint256 _current = current;
        for (uint256 i = 0; i < amount; i++) {
            _current++;
            artie.safeMint(msg.sender, _current);
        }
        current = _current;
        emit Season02Mint(msg.sender, amount, current);
    }

    function mintFromGranny(uint256 amount, uint256 tokenId) external payable grannyMintEnabled onlyWallets {
        require(amount > 0, "Must mint at least one token");
        require(grannyDiskPrice * amount == msg.value, "INCORRECT_ETH_AMOUNT");
        require(current + amount <= MAX_TOKEN, "MAX_TOKENS_EXCEEDED");
        uint256 usedTokenId = mintTokenIds[tokenId];
        require(usedTokenId != 0, "TokenId is not a valid burnable tokenId for minting");
        //Burn the Granny Token; will only succeed if the msg.sender has a sufficient amount of tokenId in their wallet
        dispensary.safeBurn(msg.sender, tokenId, amount);
        //Mint the Used version of the Granny token to the sender's wallet
        dispensary.safeMint(msg.sender, usedTokenId, amount, '');
        //Mint from Artie
        uint256 _current = current;
        for (uint256 i = 0; i < amount; i++) {
            _current++;
            artie.safeMint(msg.sender, _current);
        }
        current = _current;
        emit Season02Mint(msg.sender, amount, current);
    }

    function batchFreeMintFromGranny(uint256[] calldata amounts, uint256[] calldata tokenIds) external grannyMintEnabled onlyWallets {
        require(amounts.length == tokenIds.length, "Array length mismatch");
        for (uint256 i = 0; i < amounts.length; i++) {
            freeMintFromGranny(amounts[i], tokenIds[i]);
        }
    }

}