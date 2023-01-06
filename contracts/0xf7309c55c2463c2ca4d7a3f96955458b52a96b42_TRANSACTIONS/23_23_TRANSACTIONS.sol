// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.15;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@projectopensea/operator-filter-registry/src/DefaultOperatorFilterer.sol";

/** 

    * @title THE TRANSACTIONS 
    * @author your friendly neighborhood CURION (@curi0n)
    * @dev NFT contract for THE TRANSACTIONS, uses ONLY the OpenSea's Operator Filter Registry! (DefaultOperatorFilterer)

*/

contract TRANSACTIONS is ERC1155, Ownable, RrpRequesterV0, DefaultOperatorFilterer {
    using Strings for uint256;

    string public name = "The Transactions";
    string public symbol = "TXN";

    address public airnode;
    address public paymentSplitterAddress;
    address public pendingsAddress;
    address public sponsorAddressWhichIsNotSponsorWallet;
    address public sponsorWallet;

    bool public revealed = false;
    bool public paused = false;
    bool public randIdIsOn = true;

    bytes32 public endpointIdUint256Array;

    string private baseURI;
    string private unrevealedBaseURI;

    uint256 public totalMinted = 0; //minted amount
    uint256 public qrngGasForwarded; //gas forwarded to airnode sponsor wallet

    uint256 public pendingsSupply = 998;
    uint256 public blurVictimSupply = 9;
    uint256 public nominalMaxSupply = 2000;
    uint256 public totalSupply = nominalMaxSupply + blurVictimSupply;
    uint256 public totalMintedPostClaim = 0; //backup incase RNG gets wonky

    uint256 public mintPhase = 0;
    uint256 public mintPrice = 0.072 ether;

    uint256[] public remainingIds; //remaining ids to be minted after pendings holders 999-2000
    uint256[] public lastMintedIds;

    //pendings
    mapping (uint256 => bool) public usedInFreeMintPendingIds; //used to check whether pending has been used for free 1:1 for Pendings holders
    mapping (uint256 => bool) public usedInPaidMintPendingIds; //used to check whether pending has been used for paid 1:1 for Pendings holders

    //blocks/transactions
    mapping(address => uint256) public amountMinted;
    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;
    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => uint256) public requestIdToOriginFunction;
    mapping(bytes32 => uint256) public requestIdToReservedId;

    //have to update these on mint/burn/transfer
    mapping(address => uint256[]) public ownedIds;
    mapping(address => uint256) public amountMintedPerAddressWhitelist;
    mapping(address => uint256) public amountMintedPerAddressPublic;

    error MaxSupplyReached();
    error ForwardFailed();
    error InsufficientFunds();
    error MintIsClosed();
    error UnknownAirnodeRequestId();
    error InvalidId();
    error NoOwnedIds();
    error NoRemainingIds();

    error PendingAlreadyUsedInFreeMint();
    error ZeroPendingsBalance();
    error NotOwnerOfThisPendings();
    error PendingAlreadyUsedForPaidMint();
    error IdNotFoundInArray();
    error TooManyAddresses();
    error OnlyContractOrOwnerCanCall();
    error MintLimitPerWalletReached();

    event RequestedUint256Array(bytes32 indexed requestId, uint256 size);
    event ReceivedUint256Array(bytes32 indexed requestId, uint256[] response);
    event TransactionMinedFromBlock(uint256 indexed _id, address _sender, bytes32 _requestId);

    constructor(address _airnodeRrp) ERC1155("") RrpRequesterV0(_airnodeRrp) {}

    // fallback payable functions for anything sent to contract not via mint functions
    receive() external payable {} //msg.data must be empty
    fallback() external payable {} //when msg.data is not empty

    //================================================================
    // MINTING BLOCKS
    //================================================================

    //mint batch of blocks with owned pendings Ids. must own all supplied Ids or will revert.
    //if public mint, ids argument only serves to give quantity of mint for batch mint, no effect on single mint
    
    function batchClaimPendingsOwner(uint256[] memory _pendingsIds) public {
        for(uint256 i = 0; i < _pendingsIds.length; i++){
            claimSinglePendingsOwner(_pendingsIds[i]);
        }
    }

    function batchMintPendingsOwner(uint256[] memory _pendingsIds) public payable {
        for(uint256 i = 0; i < _pendingsIds.length; i++){
            mintSingleBlockPendingsHolderWhitelist(_pendingsIds[i]);
        }
    }

    // send transaction to generate a block wity RN-based outcome of ID
    function mintSinglePublic() public payable {
        if(paused){ revert MintIsClosed(); }
        address sender = msg.sender;

        if(mintPhase == 0){ revert MintIsClosed(); }
        if(msg.value < mintPrice + qrngGasForwarded) { revert InsufficientFunds(); }
        if(totalMinted == nominalMaxSupply){revert MaxSupplyReached(); }

        if(amountMintedPerAddressPublic[sender] > 0){ revert MintLimitPerWalletReached(); }

        totalMintedPostClaim++;

        //remove last persons minted ID from remainingIds
        if(lastMintedIds.length > 0){
            removeIdFromRemainingIds(lastMintedIds[0]);
        }

        (bool fwd, ) = sponsorWallet.call{value: qrngGasForwarded }(""); 
        if(!fwd){ revert ForwardFailed(); }
        
        requestRandomTransactionOutcome(sender, 3, 9999);  
    }

    //most people have 1 or 2 pendings so this might be more gas efficient to define the function in terms of single mints
    function claimSinglePendingsOwner(uint256 _pendingsId) public {
        if(paused){ revert MintIsClosed(); }
        
        address sender = msg.sender;

        if(mintPhase == 0){ revert MintIsClosed(); }
        if(totalMinted == nominalMaxSupply){revert MaxSupplyReached(); }
        
        if((IERC721(pendingsAddress).balanceOf(sender) == 0)) { revert ZeroPendingsBalance(); }
        if(!(IERC721(pendingsAddress).ownerOf(_pendingsId) == sender)) { revert NotOwnerOfThisPendings(); }
        
        if(usedInFreeMintPendingIds[_pendingsId]){ revert PendingAlreadyUsedInFreeMint(); }
        usedInFreeMintPendingIds[_pendingsId] = true;
        totalMinted++;

        requestRandomTransactionOutcome(sender, 1, _pendingsId);  

        emit TransferSingle(sender, address(0), sender, _pendingsId, 1);
    }

    function mintSingleBlockPendingsHolderWhitelist(uint256 _pendingsId) public payable {
        if(paused){ revert MintIsClosed(); }
        //user must own the pending they have a balance of > 0 with, must have mintPrice+forwardingFee for airnode
        //this pendingsId must not have been used before to mint a block
        address sender = msg.sender;
        if(mintPhase == 0){ revert MintIsClosed(); }       
        if(totalMinted == nominalMaxSupply){revert MaxSupplyReached(); }
        if(msg.value < mintPrice + qrngGasForwarded) { revert InsufficientFunds(); }
        
        if((IERC721(pendingsAddress).balanceOf(sender) == 0)) { revert ZeroPendingsBalance(); }
        if(!(IERC721(pendingsAddress).ownerOf(_pendingsId) == sender)) { revert NotOwnerOfThisPendings(); }
        if(amountMintedPerAddressWhitelist[sender] > IERC721(pendingsAddress).balanceOf(sender)){ revert MintLimitPerWalletReached(); }
        if(usedInPaidMintPendingIds[_pendingsId]){ revert PendingAlreadyUsedForPaidMint(); }
        
        usedInPaidMintPendingIds[_pendingsId] = true;
        totalMinted++;
        totalMintedPostClaim++;
        amountMintedPerAddressWhitelist[sender]++;

        //remove last persons minted ID from remainingIds
        if(lastMintedIds.length > 0){
            removeIdFromRemainingIds(lastMintedIds[0]);
        }


        (bool fwd, ) = sponsorWallet.call{value: qrngGasForwarded }(""); 
        if(!fwd){ revert ForwardFailed(); }

        requestRandomTransactionOutcome(sender, 2, 9999);  

        emit TransferSingle(sender, address(0), sender, _pendingsId, 1); 

    }

    /// @notice sends request to QRNG generator to get a random number
    function requestRandomTransactionOutcome(address _minter, uint256 _originFunctionId, uint256 _pendingsId) private {
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256Array,
            sponsorAddressWhichIsNotSponsorWallet,
            sponsorWallet,
            address(this),
            this.fulfillMint.selector, //specified callback function
            // Using Airnode ABI to encode the parameters
            abi.encode(bytes32("1u"), bytes32("size"), 1)
        );
        expectingRequestWithIdToBeFulfilled[requestId] = true;
        requestIdToSender[requestId] = _minter;
        requestIdToOriginFunction[requestId] = _originFunctionId;
        requestIdToReservedId[requestId] = _pendingsId;
        emit RequestedUint256Array(requestId, 1);
    }

    /// @dev see the pun here? :)
    function fulfillMint(bytes32 _requestId, bytes calldata data) external onlyAirnodeRrp {
        
        if( !expectingRequestWithIdToBeFulfilled[_requestId] ) { revert UnknownAirnodeRequestId(); }
        expectingRequestWithIdToBeFulfilled[_requestId] = false;
        
        uint256[] memory qrngUint256Array = abi.decode(data, (uint256[]));
        address sender = requestIdToSender[_requestId];
        uint256 thisOriginFunctionId = requestIdToOriginFunction[_requestId];
        uint256 thisReservedId = requestIdToReservedId[_requestId];

        //testing 
        uint256 thisId;
        if(thisOriginFunctionId==1){
            thisId = thisReservedId;
        } else {
            if(randIdIsOn){
                thisId = getIdFromQrnAndManageSupply(qrngUint256Array[0]);
            } else {
                thisId = pendingsSupply+totalMintedPostClaim; //this is incremented in the mint functions
            }            
        }

        ownedIds[sender].push(thisId);
        _mint(sender, thisId, 1, "");  

        emit TransactionMinedFromBlock(thisId, sender, _requestId);
    }

    /**
    @notice Returns the ID of the token to be minted via random selection without replacement. Remaining IDS starts as 999-2000 
    */ 
    function getIdFromQrnAndManageSupply(uint256 _QRN) private returns (uint256) {
        uint256 thisRandomIndex = (_QRN % remainingIds.length-1); //includes 0 because this gets an index not an ID. max index is length-1.
        uint256 thisRandomId = remainingIds[thisRandomIndex];
        lastMintedIds.push(thisRandomId);
        //remove this ID from the remainingIds array
        return thisRandomId;
    }

    function airdropToBlurVictims(address[] memory _addresses) public onlyOwner {
        if(_addresses.length > blurVictimSupply){ revert TooManyAddresses(); }
        for(uint256 i=0; i < _addresses.length; i++){
            _mint(_addresses[i], nominalMaxSupply+i+1, 1, "");
        }
    }

    //================================================================
    // HELPERS
    //================================================================

    //find desired ID, move last ID to its place, pop last ID
    function removeIdFromRemainingIds(uint256 _id) private {
        if(remainingIds.length == 0){ revert NoRemainingIds(); }
        if(_id > nominalMaxSupply){ revert InvalidId(); }

        for(uint256 i=0; i < remainingIds.length; i++){
            if(remainingIds[i] == _id){
                remainingIds[i] = remainingIds[remainingIds.length-1];
                remainingIds.pop();
            }
        }
    }

    //check case of ONE owned!
    function removeIdFromOwnedIds(address _user, uint256 _id) private {
        
        if(ownedIds[_user].length == 0){ revert NoOwnedIds(); }
        if(_id > nominalMaxSupply){ revert InvalidId(); }

        for(uint256 i=0; i < ownedIds[_user].length; i++){
            if(ownedIds[_user][i] == _id){
                ownedIds[_user][i] = ownedIds[_user][ownedIds[_user].length-1];
                ownedIds[_user].pop();
            } 
        }
    }

    //in the case that not all free mints are claimed, add these Ids to the remainingIds array
    function addUnusedFreeMintsToRemainingIds() public onlyOwner {
        for(uint256 i=1; i <= pendingsSupply; i++){
            if(!usedInFreeMintPendingIds[i]){
                remainingIds.push(i);
            }
        }
    }

    //================================================================
    // GETTERS
    //================================================================

    function getHasPendingsIdBeenUsedForFreeBlockMint(uint256 _pendingsId) public view returns(bool) {
        return usedInFreeMintPendingIds[_pendingsId];
    }

    function getHasPendingsIdBeenUsedForPaidBlockMint(uint256 _pendingsId) public view returns(bool) {
        return usedInPaidMintPendingIds[_pendingsId];
    }

    function getOwnedIds(address _owner) public view returns(uint256[] memory) {
        return ownedIds[_owner];
    }

    function uri(uint256 _id) public view override returns (string memory) {
        if(_id > totalSupply) { return "Id is beyond max";}
        else {
            if(revealed){
                return string(abi.encodePacked(baseURI, Strings.toString(_id),".json")); 
            } else {
                return string(abi.encodePacked(unrevealedBaseURI, Strings.toString(_id),".json")); 
            }
        }
    }

    function totalMintedSoFar() public view returns (uint256) {
        return totalMinted;
    }

    //================================================================
    // SETTERS, OVERRIDES, MISC
    //================================================================

    function setAirnodeRequestParameters(
        address _airnode, //goerli: 0x9d3C147cA16DB954873A498e0af5852AB39139f2
        bytes32 _endpointIdUint256Array, //goerli: 0x27cc2713e7f968e4e86ed274a051a5c8aaee9cca66946f23af6f29ecea9704c3
        address _sponsorWallet, //derived with this contract address
        address _sponsorAddressWhichIsNotSponsorWallet, //this contract address or creator EOA
        uint256 _qrngGasForwarded
    ) external onlyOwner {
        airnode = _airnode;
        endpointIdUint256Array = _endpointIdUint256Array;
        sponsorWallet = _sponsorWallet;
        sponsorAddressWhichIsNotSponsorWallet = _sponsorAddressWhichIsNotSponsorWallet;
        qrngGasForwarded = _qrngGasForwarded;
    }

    // generates id array of 999-2000 for random selection based mints
    function setIdArray() public onlyOwner {
        for(uint256 i=pendingsSupply+1; i <= nominalMaxSupply; i++){
            remainingIds.push(i);
        }
    }

    function setRandIsOn(bool _randIdIsOn) public onlyOwner {
        randIdIsOn = _randIdIsOn;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setUnrevealedBaseURI(string memory _uri) public onlyOwner {
        unrevealedBaseURI = _uri;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPendingsAddress(address _pendingsAddress) public onlyOwner {
        pendingsAddress = _pendingsAddress;
    }

    function setMintPhase(uint256 _phase) public onlyOwner {
        mintPhase = _phase;
    }

    function setPaymentSplitterAddress(address payable _paymentSplitterAddress) public onlyOwner {
        paymentSplitterAddress = payable(_paymentSplitterAddress);
    }

    function setMintPrice(uint256 _publicMintCost) public onlyOwner {
        mintPrice = _publicMintCost;
    }

    function setBlurVictimSupply(uint256 _blurVictimSupply) public onlyOwner {
        blurVictimSupply = _blurVictimSupply;
        totalSupply = nominalMaxSupply + blurVictimSupply;
    }

    function setQrngGasForwarded(uint256 _qrngGasForwarded) public onlyOwner {
        qrngGasForwarded = _qrngGasForwarded;
    }

    //================================================================
    // WITHDRAWALS
    //================================================================

    function withdrawERC20FromContract(address _to, address _token) external onlyOwner {
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }

    //if this doesnt work, import IAirnodeRrpV0.sol and use airnodeRrpInterface.requestWithdrawal(airnode, sponsorWallet);
    function withdrawEthFromSponsorWallet() external onlyOwner {
        airnodeRrp.requestWithdrawal(airnode, sponsorWallet);
    }

    function withdrawEthFromContract() external onlyOwner  {
        (bool os, ) = payable(paymentSplitterAddress).call{ value: address(this).balance }('');
        if(!os){ revert ForwardFailed(); }
    }

    //================================================================
    // OPENSEA OPERATOR FILTERING - RELATED OVERRIDES
    //================================================================

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        
        //added update to mappings which track owned IDs
        if(from != address(0)) {
            removeIdFromOwnedIds(from, tokenId);
            ownedIds[to].push(tokenId);
        }

        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {

        //added update to mappings which track owned IDs
        if(from != address(0)) {
            for(uint256 i=0; i < ids.length; i++) {
                removeIdFromOwnedIds(from, ids[i]);
                ownedIds[to].push(ids[i]);
            }
        }

        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }


}