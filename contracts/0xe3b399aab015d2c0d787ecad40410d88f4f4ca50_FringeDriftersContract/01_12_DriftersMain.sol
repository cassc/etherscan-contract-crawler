//SPDX-License-Identifier: MIT
//Fringe Drifter Main Contract Created by Swifty.eth

//legal: https://fringedrifters.com/terms

pragma solidity ^0.8.0;

import "contracts/ERC721SW.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";



interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address _from) external returns (uint256);
}

//errors
error NotWithdrawAddress();
error FailedToWithdraw();
error NotMinting();
error NotEnoughEth();
error PastBoundsOfBatchLimit();
error PastSupply();
error AlreadyMinted();
error AuthenticationFailed();
error DoesNotExist();

contract FringeDriftersContract is ERC721SW, Ownable {


    //library integration.
    using ECDSA for bytes32;

    //modifiers.
    modifier withdrawAddressCheck() {
        if (msg.sender != withdrawAccount) revert NotWithdrawAddress();
        _;
    }
    


    //initialization of globals.
    uint256 public FD_PRICE = 0.08 ether;
    uint256 public MAXBATCH = 20;
    string internal _tokenBaseURI;
    string public CURRENTPHASE;
    address private signerAddress;
    
    //storage of all previous transaction IDs to prevent against forgery attacks.
    mapping(string => bool) public usedTransactions;

    //withdraw account.
    address private withdrawAccount = 0x8ff8657929a02c0E15aCE37aAC76f47d1F5fbfC6; //needs to be changed for final.

    //stores information on each colour world, where it starts and ends as well how far into the colour world it is.
    struct Phase {
        uint64 startingPoint;
        uint64 endPoint;
        uint64 currentCount;
    }

    bool public isMinting = false;

    //stores a dictionary for colour world name to its phase storage.
    mapping(string => Phase) public AllPhases;

    //constructor, which also sets signer address as well as tokenbaseURI.
    constructor( 
        string memory baseURI, address startingSignerAddress
    ) ERC721SW("Fringe Drifters", "FD") {
        _tokenBaseURI = baseURI;
        signerAddress = startingSignerAddress;
    }
    

    //change functions.
    function adjustPhases(string calldata PhaseName, uint64 startPoint, uint64 endPoint) external onlyOwner {
        AllPhases[PhaseName].startingPoint = startPoint;
        AllPhases[PhaseName].endPoint = endPoint;

        if (endPoint > _currentIndex) { //sets upper bound _currentIndex to the highest number currently needed.
            _currentIndex = endPoint; 
        }
    }

    //changes current phase which everyone mints on.
    function changePhase(string calldata newPhase) external onlyOwner {
        CURRENTPHASE = newPhase;
    }

    //gets supply for specific phase
    function getSupplyForPhase(string calldata PhaseName) external view returns (uint64){
        return AllPhases[PhaseName].currentCount;
    }

    //adjusts price of drifter.
    function adjustPrice(uint256 newPrice) external onlyOwner {
        FD_PRICE = newPrice;
    }

    //adjusts the maximum amount of allowed drifters to be minted at once (capped to 20 for gas reasons.)
    function adjustMaxBatch(uint256 maxBatch) external onlyOwner {
        MAXBATCH = maxBatch;
    }

    //toggles the mint.
    function toggleMint() external onlyOwner {
        isMinting = !isMinting;
    }


    //sets a new signer incase of worst case scenario.
    function adjustSigner(address newSigner) external onlyOwner {
        signerAddress = newSigner;
    }


    //gifts drifters in bulk, with specified colour world.
    function gift(string calldata phase, address[] calldata receivers) external onlyOwner {
        //gets selected colour world (or phase) information.
        Phase storage CurrentPhaseInfo = AllPhases[phase];

        uint256 startingIndex = CurrentPhaseInfo.startingPoint+CurrentPhaseInfo.currentCount; //gets starting index to start to mint from.

        if (startingIndex + receivers.length > CurrentPhaseInfo.endPoint) revert PastSupply(); //checks if it is past supply of colour world.

        
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1, startingIndex+i);
        }//bulk mints.

        //increments colour world counter.
        CurrentPhaseInfo.currentCount += (uint64)(receivers.length); //typecast to uint64

    }

    

    function totalBalance() external view returns (uint256) { //gets total balance in account.
        return payable(address(this)).balance;
    }

    //changes withdraw address if needed.
    function changeWithdrawer(address newAddress) external withdrawAddressCheck() {
        withdrawAccount = newAddress;
    }

    //withdraws all eth funds.
    function withdrawFunds() external withdrawAddressCheck {
        (bool success, bytes memory _data) = payable(msg.sender).call{value: this.totalBalance()}("");
        if (!success) revert FailedToWithdraw();
    }

    //withdraws ERC20 tokens.
    function withdrawERC20(IERC20 erc20Token) external withdrawAddressCheck {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    //sets new baseURI
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    //tokenURI handler.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721SW)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert DoesNotExist();
        
        return
            string(
                abi.encodePacked(
                    _tokenBaseURI,
                    Strings.toString(tokenId),
                    string(".json")
                )
            );
    }

    //verifies the signature matches.
    function verifyAddressSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
        return signerAddress == hash.toEthSignedMessageHash().recover(signature);
    }

    //hashes transaction for comparison.
    function hashTransaction(address sender, string memory transactionID, uint256 tokenQuantity) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(sender, transactionID, tokenQuantity));
          return hash;
    }


    //main mint function.
    function FringeMint(
        bytes32 hash, bytes memory signature, string memory transactionID, uint256 qty
    ) external payable {
        if (!isMinting) revert NotMinting(); //ensures minting is active.


        if (!verifyAddressSigner(hash, signature)) revert AuthenticationFailed(); //webserver does the checks to see wether or not you are allowed to mint, this includes the checks for the various phases.
        if (usedTransactions[transactionID]) revert AuthenticationFailed(); //checks if transaction has already been used.
        if (!(hashTransaction(msg.sender, transactionID, qty) == hash)) revert AuthenticationFailed(); //checks if the hash matches up.
        if (msg.value != (FD_PRICE * qty)) revert NotEnoughEth(); //checks if enough eth.
        if (qty > MAXBATCH) revert PastBoundsOfBatchLimit(); //ensures it doesnt go over max allowed batch.

        Phase storage CurrentPhaseInfo = AllPhases[CURRENTPHASE]; //gets current phase information for use.
        uint256 currentIndexForPhase = CurrentPhaseInfo.startingPoint+CurrentPhaseInfo.currentCount; //gets starting index to mint from.



        if ((currentIndexForPhase + qty) > CurrentPhaseInfo.endPoint) revert PastSupply(); //ensures that there is enough supply to mint for this colour world.

        _safeMint(msg.sender, qty, currentIndexForPhase); //safely mints for that allowed quantity.
        CurrentPhaseInfo.currentCount += (uint64)(qty); //increments phase amount.

        usedTransactions[transactionID] = true; //uses transaction id to prevent it from being used again.
    }
}