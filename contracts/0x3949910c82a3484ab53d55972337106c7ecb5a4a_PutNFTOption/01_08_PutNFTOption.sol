// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

enum ItemType {
    ERC20,
    ERC721,
    ERC1155,
    OTHER
}
/**
for a put option, here are the things we need to do:
// seller placing order
1. seller set up a put option by locking ETH to the contract
2. buyer pay the ETH to buy the put option contract

//buyer placing order 
1. buyer sign a request for WETH
2. seller can take the request by locking ETH and take WETH as fee
3. verify the signature
    a. check if signature valid
    b. check if signature expired

// executing contract 
1. buyer can execute the contract by sending the NFT to seller and get the ETH locked in the contract

// modify contract
1. seller can adjust the contract anytime he wants as long as no one is buying the contract
2. seller can also withdraw the fund anytime

// sign order
1. provide a sign otder method to make signature
*/

error PutOption__InsufficientFund();
error PutOption__ContractNotAvailable();
error PutOption__AssetNotSupported();

contract PutNFTOption is Ownable {



    // Config for the smart contract
    // Todo WETH_ADDRESS
    address public S_WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public s_contractCommission = 25; // 2.5%
    bytes4 public constant ERC1155InterfaceId = 0xd9b67a26;
    bytes4 public constant ERC721InterfaceId = 0x80ac58cd;
    mapping(address => bool) public s_whitelistedAddresses; 

    // 1. get available contract 
    OptionContract[] public s_allContracts;

    // 2. get finished contract 
    uint256[] public s_finishedcontractIDs; 


    // 3. get contract by user address
    //    store all contract finishedcontractIDs when exercised, deactivated
    //    get the length of all finishedcontractIDs
    //    loop the array to get the IDs
    mapping(address => uint256[]) public s_contractIDToHost;

    // store the cancelled and fulfilled signature
    mapping(bytes => bool) public s_invalidSignatures; 

    // EVENETS 
    event ContractCreated(uint contractID, address host, address nftAddr);
    event BuyContract(uint contractID, address player);
    event ContractExercised(uint contractID, uint nftID);
    event OrderFulfilled(uint contractID, bytes signature);
    event ContractDeactivated(uint contractID);


    struct OptionContract { 
    
        bool active;
        bool exercised;
        ItemType itemType;
        
        address seller;
        address buyer;

        Order order;

        uint256 totalIncome;
        uint256 ethBalance;
        
    }
    struct Order{
        address nftAddr; 
        uint256 strikePrice; 
        uint256 premium; 
        uint256 duration;
        uint256 expieryDate;
    }

    constructor (address[] memory _addressesToWhitelist) {

        for (uint256 index = 0; index < _addressesToWhitelist.length; index++) {
            require(s_whitelistedAddresses[_addressesToWhitelist[index]] != true, "Address is already whitlisted");
            s_whitelistedAddresses[_addressesToWhitelist[index]] = true;
        }        
    }


    function getInterfaceType(address _nft) public view returns (ItemType) {
        IERC165 _thisNFT = IERC165(_nft);
        if (_thisNFT.supportsInterface(ERC1155InterfaceId)) 
            return ItemType.ERC1155;
        else if (_thisNFT.supportsInterface(ERC721InterfaceId))
            return ItemType.ERC721;
        else 
            return ItemType.OTHER;
    } 
    
    // when nft owner deposit nft and setup the machine, return capsule ID
    /**
    * input ETH to set up a put contract
    * seller agree to buy an NFT at the strike price anytime the buyer want
    */
    function setUpContract(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration) 
        external payable
        returns (uint256 contractID)
    {   
        // check whitelisted nft
        if(isAddressWhitelisted(_assetAddress) != true) revert PutOption__AssetNotSupported();
        // require(isAddressWhitelisted(_assetAddress) == true, "Asset Address isn't whitelisted");

        // check user input enough money
        // deposit ETH to contract
        if(msg.value < (_strikePrice)) revert PutOption__InsufficientFund(); //0x4ff1292f
        uint256 _paidAmt = msg.value;
        // require(msg.value >= _strikePrice, "Insufficient fund");

        // check owner if ERC 721 or ERC 1155
        ItemType _nftType = getInterfaceType(_assetAddress);
        if(_nftType == ItemType.OTHER) revert PutOption__AssetNotSupported();

        return fulfillSetupContract(_assetAddress, _strikePrice, _premium, _duration, _paidAmt);
    }


    // when nft owner deposit nft and setup the machine, return capsule ID
    /**
    * input ETH to set up a put contract
    * seller agree to buy an NFT at the strike price anytime the buyer want
    */
    function fulfillSetupContract(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, uint256 _paidAmt) 
        internal
        returns (uint256 contractID)
    {   
        // check whitelisted nft
        if(isAddressWhitelisted(_assetAddress) != true) revert PutOption__AssetNotSupported();

        // check user input enough money
        // deposit ETH to contract
        if(_paidAmt < (_strikePrice)) revert PutOption__InsufficientFund(); //0x4ff1292f

        // check owner if ERC 721 or ERC 1155
        ItemType _nftType = getInterfaceType(_assetAddress);
        if(_nftType == ItemType.OTHER) revert PutOption__AssetNotSupported();

        // setup contract info
        uint256 _newContractID = s_allContracts.length;
        OptionContract memory c; 
        c.seller = tx.origin;
        c.active = true;
        c.itemType = _nftType;
        Order memory order;
        c.order = order;
        c.order.duration = _duration;

        // set it to expired
        c.order.expieryDate = block.timestamp;
        c.order.nftAddr = _assetAddress;
        c.order.strikePrice = _strikePrice;
        c.order.premium = _premium;

        s_contractIDToHost[tx.origin].push(_newContractID);
        // numberOfContract[tx.origin] = numberOfContract[tx.origin]+1;

        s_allContracts.push(c);

        emit ContractCreated(_newContractID, tx.origin, _assetAddress);

        return _newContractID;
    }



    function getNumberOfContractPerAddress(address _owner) public view returns (uint256 num){
        return s_contractIDToHost[_owner].length;
    }

    // player buys capsule partition
    function buyContract(uint256 _contractID) public payable
    {
        if(isContractAvailable(_contractID) != true) revert PutOption__ContractNotAvailable();

        OptionContract storage c = s_allContracts[_contractID];
        if(msg.value < c.order.premium) revert PutOption__InsufficientFund();

        c.buyer = tx.origin;
        c.totalIncome += msg.value;
        c.ethBalance += msg.value;
        c.order.expieryDate = c.order.duration + block.timestamp;

        emit BuyContract(_contractID, tx.origin);
    }

    function modifyContract(uint256 _contractID, uint256 _duration, uint256 _strikePrice, uint256 _premium) public payable{
        require(isContractAvailable(_contractID) == true, "Contract is not available.");
        OptionContract storage c = s_allContracts[_contractID];
        if(c.order.strikePrice > _strikePrice){
            uint256 withdrawAmt = c.order.strikePrice - _strikePrice;
            (bool success1, ) = (address(c.seller)).call{value: withdrawAmt }("");
            require(success1, "withdraw failed.");
        }else{
            uint256 despositAmt =  _strikePrice - c.order.strikePrice;
            if(msg.value < (despositAmt)) revert PutOption__InsufficientFund();
        }
        c.order.duration = _duration;
        c.order.strikePrice = _strikePrice;
        c.order.premium = _premium;
    }

    function deactivateContract(uint256 _contractID) public{
        if(isContractAvailable(_contractID) != true) revert PutOption__ContractNotAvailable();
        OptionContract storage c = s_allContracts[_contractID];
        require (tx.origin == c.seller, "not contract owner.");
        // deactivate
        c.active = false;

        // withdraw the collected fee 
        if(c.ethBalance > 0){
            uint256 commission = c.ethBalance * s_contractCommission/1000;
            uint256 withdrawAmt = c.ethBalance - commission;
            (bool success1, ) = (address(c.seller)).call{value: withdrawAmt }("");
            require(success1, "withdraw failed.");
            c.ethBalance  = 0;
            (bool success2, ) = owner().call{value: commission }("");
            require(success2, "withdraw commission failed.");
        }

        (bool success3, ) = (address(c.seller)).call{value: c.order.strikePrice }("");
        require(success3, "withdraw failed.");
        s_finishedcontractIDs.push(_contractID);

        emit ContractDeactivated(_contractID);
    }

    // withdraw only the fee
    function sellerWithdrawFund(uint256 _contractID) external {
        require(isContractExist(_contractID), "contract does not exist.");
        OptionContract storage c = s_allContracts[_contractID];
        require(msg.sender == c.seller, "only for seller");
        require(c.ethBalance > 0, "no available fund for withdraw.");

        // transfer fund (only the collected fee)
        uint256 commission = c.ethBalance * s_contractCommission/1000;
        uint256 withdrawAmt = c.ethBalance - commission;
        (bool success1, ) = (address(c.seller)).call{value: withdrawAmt}("");
        require(success1, "withdraw failed.");
        c.ethBalance  = 0;
        (bool success2, ) = owner().call{value: commission }("");
        require(success2, "withdraw commission failed.");
    }
    

    function cancelOffer(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, address _buyer, uint256 _effectiveDate, bytes32 _salt,
    bytes memory _signature) public{
        
        bool verified = verify(_buyer, _assetAddress, _strikePrice, _premium, _duration, _effectiveDate, _salt, _signature);
        require(verified == true, "wrong signature!");
        require(_buyer == tx.origin, "this is not your offer!");
        
        s_invalidSignatures[_signature] = true;
    }


    function fulfillOrder(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, address _buyer, uint256 _effectiveDate, bytes32 _salt,
    bytes memory _signature) public payable{
        
        //check if order valid
        require(_effectiveDate > block.timestamp, "offer expired!");
        bool verified = verify(_buyer, _assetAddress, _strikePrice, _premium, _duration, _effectiveDate, _salt, _signature);
        require(verified == true, "wrong signature!");
        require(s_invalidSignatures[_signature] != true, "offer not available.");

        if(msg.value < (_strikePrice)) revert PutOption__InsufficientFund(); //0x4ff1292f
        uint256 _paidAmt = msg.value;
        
        //stored the fulfilled 
        s_invalidSignatures[_signature] = true;
        
        // send ETH function inside the contract
        uint256 _contractID = fulfillSetupContract(_assetAddress,  _strikePrice,  _premium,  _duration,  _paidAmt);

        // ERC20 funciton, transfer WETH
        uint256 commission = _premium * s_contractCommission/1000;
        uint256 withdrawAmt = _premium - commission;
        IERC20 _weth = IERC20(S_WETH_ADDRESS);
        _weth.transferFrom(_buyer, tx.origin, withdrawAmt);
        _weth.transferFrom(_buyer, address(owner()), commission);


        OptionContract storage c = s_allContracts[_contractID];
        c.buyer = _buyer;
        c.totalIncome += _premium;
        // update the expieryDate of the option contract
        c.order.expieryDate = c.order.duration + block.timestamp;

        // emit OrderFulfilled(_contractID, _signature);
        emit BuyContract(_contractID, _buyer);

    }
    

    function exerciseContract(uint256 _contractID, uint256 _nftID) public returns(bool){
        if (_contractID < 0 || _contractID >= s_allContracts.length) 
            return false;
        OptionContract storage c = s_allContracts[_contractID];
        require (tx.origin == c.buyer, "not contract buyer.");
        require (c.order.expieryDate > block.timestamp, "contract expired");
        
        // deavtivate
        c.active = false;
        c.exercised =  true;

        // buyer sell NFT to seller
        if (c.itemType == ItemType.ERC1155){
            IERC1155 _thisNft = IERC1155(c.order.nftAddr);
            _thisNft.safeTransferFrom(c.buyer, c.seller, _nftID, 1, "");
            // withdraw ERC1155
        }
        if (c.itemType == ItemType.ERC721){
            IERC721 _thisNFT = IERC721(c.order.nftAddr);
            _thisNFT.safeTransferFrom(c.buyer, c.seller, _nftID);
            // withdraw ERC721
        }

        //sending unclaimed balance to 
        uint256 commission = (c.ethBalance) * s_contractCommission/1000;
        uint256 withdrawAmt = (c.ethBalance) - commission;
        c.ethBalance  = 0;
        (bool success1, ) = owner().call{value: commission }("");
        require(success1, "seller transfer commission failed.");
        (bool success2, ) = (address(c.seller)).call{value: withdrawAmt}("");
        require(success2, "seller withdraw failed.");

        //sending the strike price ETH in contract to buyer

        uint256 strikeCommission = (c.order.strikePrice) * s_contractCommission/1000;
        uint256 strikeAmt = (c.order.strikePrice) - strikeCommission;

        (bool success3, ) = (address(c.buyer)).call{value: strikeAmt}("");
        require(success3, "buyer withdraw failed.");
        (bool success4, ) = owner().call{value: strikeCommission }("");
        require(success4, "buyer transfer commission failed.");
        
        s_finishedcontractIDs.push(_contractID);
        emit ContractExercised(_contractID, _nftID);
        return true;
    }



    function isContractExist(uint256 _contractId) public view returns (bool) {
        if (_contractId < 0 || _contractId >= s_allContracts.length) 
            return false;

        return true;
    }


    function isContractAvailable(uint256 _contractId) public view returns (bool) {
        require(isContractExist(_contractId), "contract does not exist.");
        OptionContract memory c = s_allContracts[_contractId];
        if (c.exercised != true && c.active == true && c.order.expieryDate < block.timestamp)
            return true;

        return false;
    }

    // function getCapsuleJackpotNum(uint _contractId) public view
    //     returns (uint resultNum)
    // {
    //     require(isContractExist(_contractId), "capsule not exist.");
    //     Capsule memory c = allCapsules[_contractId];
    //     return c.jackpotNum;
    // }

    function getContractDetail(uint256 _contractId) public view
    returns(uint256, bool, bool, ItemType, address, address, address, uint256, uint256, uint256, uint256)
    {
        require(isContractExist(_contractId), "contract does not exist.");
        OptionContract memory c = s_allContracts[_contractId];
        return (
            // c.contractID,
            _contractId,
            c.active,
            c.exercised,
            c.itemType,

            c.seller,
            c.buyer,

            c.order.nftAddr, 

            c.order.strikePrice, 
            c.order.premium, 
            c.order.duration,
            c.order.expieryDate
        );
    }
    

    function getContractIncome(uint256 _contractId) public view
    returns(uint256, uint256, uint256)
    {
        require(isContractExist(_contractId), "contract does not exist.");
        OptionContract memory c = s_allContracts[_contractId];
        return (
            // c.contractID,
            _contractId,
            c.totalIncome,
            c.ethBalance
        );
    }
    
    
    function getContractNum() public view returns (uint256) 
    {
        return s_allContracts.length;
    }

    function getFinishedContractNum() public view returns (uint256) 
    {
        return s_finishedcontractIDs.length;
    }

    function getFinishedContractID(uint256 index) public view returns (uint256) 
    {
        return s_finishedcontractIDs[index];
    }

    function isAddressWhitelisted(address _whitelistedAddress) public view returns(bool) {
        return s_whitelistedAddresses[_whitelistedAddress] == true;
    }

    function addAddressesToWhitelist(address[] memory _addressesToWhitelist) public onlyOwner {
        for (uint256 index = 0; index < _addressesToWhitelist.length; index++) {
            require(s_whitelistedAddresses[_addressesToWhitelist[index]] != true, "Address is already whitlisted");
            s_whitelistedAddresses[_addressesToWhitelist[index]] = true;
        }        
    }

    function removeAddressesFromWhitelist(address[] memory _addressesToRemove) public onlyOwner {
        for (uint256 index = 0; index < _addressesToRemove.length; index++) {
            require(s_whitelistedAddresses[_addressesToRemove[index]] == true, "Address isn't whitelisted");
            s_whitelistedAddresses[_addressesToRemove[index]] = false;
        }
    }

    
    
    // not applying for now
    // function flipOnlyWhitelist() public onlyOwner {
    //     _onlyWhitelisted = !_onlyWhitelisted;
    // }

    function editContractCommission(uint256 _newAmt) external onlyOwner {
        s_contractCommission = _newAmt;
    }



    function kill() external onlyOwner {
        selfdestruct(payable(address(owner())));
    }

    //this contract is not supposed to receive any NFT, this function is an emergency exit if someone accidentally deposited their NFT
    function emergencyNFTExit(address _assetAddress, uint256 _tokenId) external onlyOwner{
        // check owner if ERC 721 or ERC 1155
        ItemType _nftType = getInterfaceType(_assetAddress);
        require(_nftType != ItemType.OTHER, "Asset is not a recognizable type of NFT");
        // deposit nft
        if (_nftType == ItemType.ERC721) {
            IERC721 _thisNFT = IERC721(_assetAddress);
            _thisNFT.transferFrom(address(this), address(owner()), _tokenId);
        } else if (_nftType == ItemType.ERC1155) {
            IERC1155 _thisNFT = IERC1155(_assetAddress);
            _thisNFT.safeTransferFrom(address(this), address(owner()), _tokenId, 1, "");
        }

    }



    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }




    // code for signature and verification
    function getMessageHash(address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, uint256 _effectiveDate, bytes32 salt)public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_assetAddress, _strikePrice, _premium, _duration, _effectiveDate, salt));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }


    //verify the signed messaged
    function verify(
        address _signer,
        address _assetAddress, uint256 _strikePrice, uint256 _premium, uint256 _duration, uint256 _effectiveDate, bytes32 salt,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_assetAddress, _strikePrice, _premium, _duration, _effectiveDate, salt);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }

    function setWETHAddress(address _wethAdddress) public {
        S_WETH_ADDRESS = _wethAdddress;
    }
}


// todo: review and remove all unnecessary comment