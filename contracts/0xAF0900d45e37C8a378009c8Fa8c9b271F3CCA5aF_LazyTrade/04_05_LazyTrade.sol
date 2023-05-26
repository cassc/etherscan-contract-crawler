// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ContextUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./interfaceLib.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _onlyOwner() private view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

contract VerifySignature {
    function getMessageHash(
        address _to,
        uint _amount,
        string memory _message,
        uint _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
    function verify(
        address _to,
        uint256 _amount,
        string memory _message,
        uint _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _to;
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

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

contract LazyTrade is Initializable, OwnableUpgradeable, VerifySignature {
    event OrderPlace(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed value
    );
    event CancelOrder(address indexed from, uint256 indexed tokenId);
    event ColletionId(uint256 indexed collectionId, uint256 indexed cRoyalty);
    event ChangePrice(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed value
    );
    event Create(
        address indexed _from,
        address indexed _to,
        uint256 indexed tokenId,
        string status
    );
    using SafeMathUpgradeable for uint256;

    function initialize() public initializer {
        __Ownable_init();
        serviceValue = 0;
        sellervalue = 2500000000000000000;
        deci = 18;
        publicMint = true;
        _tid = 1;
    }

    struct Order {
        uint256 tokenId;
        uint256 price;
        address contractAddress;
    }
    mapping(address => mapping(uint256 => Order)) public order_place;
    mapping(string => address) private tokentype;
    mapping(address => mapping(address => bool)) public approveStatus;
    mapping(uint256 => collectionRoyalty) public cRoyaltyDetails;
    struct collectionRoyalty {
        uint256 tokenId;
        uint256 colletionRoyalty;
        address[] spliters;
        uint256[] splitpercentage;
    }
    uint256 private serviceValue;
    uint256 private sellervalue;
    bool public publicMint;
    address public lazy721;
    address public lazy1155;
    uint256 deci;
    uint256 public _tid;
    address public lazyTicket1155;

    function getApproveStatus(address owneraddrrss, address contractaddress)
        public
        view
        returns (bool)
    {
        return approveStatus[owneraddrrss][contractaddress];
    }

    function getServiceFee() public view returns (uint256, uint256) {
        return (serviceValue, sellervalue);
    }

    function setServiceValue(uint256 _serviceValue, uint256 sellerfee)
        public
        onlyOwner
    {
        serviceValue = _serviceValue;
        sellervalue = sellerfee;
    }

    function getTokenAddress(string memory _type)
        public
        view
        returns (address)
    {
        return tokentype[_type];
    }

    function addTokenType(string[] memory _type, address[] memory tokenAddress)
        public
        onlyOwner
    {
        require(
            _type.length == tokenAddress.length,
            "Not equal for type and tokenAddress"
        );
        for (uint256 i = 0; i < _type.length; i++) {
            tokentype[_type[i]] = tokenAddress[i];
        }
    }

    function pERCent(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        uint256 result = value1.mul(value2).div(1e20);
        return (result);
    }

    function calc(
        uint256 amount,
        uint256 royal,
        uint256 _serviceValue,
        uint256 _sellervalue
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fee = pERCent(amount, _serviceValue);
        uint256 roy = pERCent(amount, royal);
        uint256 netamount = 0;
        if (_sellervalue != 0) {
            uint256 fee1 = pERCent(amount, _sellervalue);
            fee = fee.add(fee1);
            netamount = amount.sub(fee1.add(roy));
        } else {
            netamount = amount.sub(roy);
        }
        return (fee, roy, netamount);
    }

    function orderPlace(
        uint256 tokenId,
        uint256 _price,
        address _conAddress,
        address from,
        uint256 _type,
        string memory status
    ) public {
        if (
            keccak256(abi.encodePacked((status))) ==
            keccak256(abi.encodePacked(("lazy")))
        ) {
            require(_price > 0, "Price Must be greater than zero");
            approveStatus[msg.sender][_conAddress] = true;
            Order memory order;
            order.tokenId = tokenId;
            order.price = _price;
            order.contractAddress = _conAddress;
            order_place[from][tokenId] = order;
            emit OrderPlace(from, tokenId, _price);
        } else {
            if (_type == 721) {
            require(
                IERC721Upgradeable(_conAddress).ownerOf(tokenId) == msg.sender,
                "Not a Owner"
            );
        } else {
            require(
                IERC1155Upgradeable(_conAddress).balanceOf(
                    msg.sender,
                    tokenId
                ) > 0 || IERC1155Upgradeable(_conAddress).balanceOf(address(this),tokenId)>0,
                "Not a Owner"
            );
        }
            require(_price > 0, "Price Must be greater than zero");
            approveStatus[msg.sender][_conAddress] = true;
            Order memory order;
            order.tokenId = tokenId;
            order.price = _price;
            order.contractAddress = _conAddress;
            order_place[msg.sender][tokenId] = order;
            emit OrderPlace(msg.sender, tokenId, _price);
        }
    }

    function cancelOrder(uint256 tokenId) public {
        delete order_place[msg.sender][tokenId];
        emit CancelOrder(msg.sender, tokenId);
    }

    function changePrice(uint256 value, uint256 tokenId) public {
        require(value < order_place[msg.sender][tokenId].price);
        order_place[msg.sender][tokenId].price = value;
        emit ChangePrice(msg.sender, tokenId, value);
    }
    
    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType, isd[4] - collectionId
    function saleToken(
        address payable from,
        uint256[] memory ids,
        address _conAddr
    ) public payable {
        require(
            ids[1] == order_place[from][ids[0]].price.mul(ids[2]) &&
                order_place[from][ids[0]].price.mul(ids[2]) > 0,
            "Order Mismatch"
        );
        _saleToken(from, ids, "Coin", _conAddr);
        if (ids[3] == 721) {
            IERC721Upgradeable(_conAddr).safeTransferFrom(
                from,
                msg.sender,
                ids[0]
            );
                if (order_place[from][ids[0]].price > 0) {
                    delete order_place[from][ids[0]];
                }
        } else {
            if (IERC1155Upgradeable(_conAddr).balanceOf(from, ids[0]).sub(ids[2]) == 0) {
                if (order_place[from][ids[0]].price > 0) {
                    delete order_place[from][ids[0]];
                }
            }
            IERC1155Upgradeable(_conAddr).safeTransferFrom(
                from,
                msg.sender,
                ids[0],
                ids[2],
                ""
            );
        }
    }

    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType
    //ldatas[0] = _royal, ldatas[1] = Tokendecimals, ldatas[2] = approveValue, ldatas[3] = _adminfee,
    //ldatas[4] = roy, ldatas[5] = netamount, ldatas[6] = val
    function _saleToken(
        address payable from,
        uint256[] memory ids,
        string memory bidtoken,
        address _conAddr
    ) internal {
        uint256[7] memory ldatas;
        ldatas[6] = pERCent(ids[1], serviceValue).add(ids[1]);
        address create;
        if(lazy721 == _conAddr || lazy1155 == _conAddr){
            if (ids[3] == 721) {
            (create, ldatas[0]) = LazyCollective721(lazy721)
                .getCreatorsAndRoyalty(ids[0]);
        } else {
            (create, ldatas[0]) = LazyCollective1155(lazy1155)
                .getCreatorsAndRoyalty(ids[0]);
        }
        }
        if (
            keccak256(abi.encodePacked((bidtoken))) ==
            keccak256(abi.encodePacked(("Coin")))
        ) {
            require(msg.value == ldatas[6], "Mismatch the msg.value");
            (ldatas[3], ldatas[4], ldatas[5]) = calc(
                ids[1],
                ldatas[0],
                serviceValue,
                sellervalue
            );
            require(
                msg.value == ldatas[3].add(ldatas[4].add(ldatas[5])),
                "Missmatch the fees amount"
            );
            if (ldatas[3] != 0) {
                payable(owner()).transfer(ldatas[3]);
            }
            if (ldatas[4] != 0) {
                payable(create).transfer(ldatas[4]);
            }
            if (ldatas[5] != 0) {
                from.transfer(ldatas[5]);
            }
        } else {
            IERC20Upgradeable t = IERC20Upgradeable(tokentype[bidtoken]);
            ldatas[1] = deci.sub(t.decimals());
            ldatas[2] = t.allowance(msg.sender, address(this));
            (ldatas[3], ldatas[4], ldatas[5]) = calc(
                ids[1],
                ldatas[0],
                serviceValue,
                sellervalue
            );
            if (ldatas[3] != 0) {
                t.transferFrom(
                    msg.sender,
                    owner(),
                    ldatas[3].div(10**ldatas[1])
                );
            }
            if (ldatas[4] != 0) {
                t.transferFrom(
                    msg.sender,
                    create,
                    ldatas[4].div(10**ldatas[1])
                );
            }
            if (ldatas[5] != 0) {
                t.transferFrom(msg.sender, from, ldatas[5].div(10**ldatas[1]));
            }
        }
    }

    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType
    function saleWithToken(
        string memory bidtoken,
        address payable from,
        uint256[] memory ids,
        address _conAddr
    ) public {
        require(
            ids[1] == order_place[from][ids[0]].price.mul(ids[2]),
            "Order is Mismatch"
        );
        _saleToken(from, ids, bidtoken, _conAddr);
        if (ids[3] == 721) {
            IERC721Upgradeable(_conAddr).safeTransferFrom(
                from,
                msg.sender,
                ids[0]
            );
                if (order_place[from][ids[0]].price > 0) {
                    delete order_place[from][ids[0]];
                }
        } else {
            if (IERC1155Upgradeable(_conAddr).balanceOf(from, ids[0]).sub(ids[2]) == 0) {
                if (order_place[from][ids[0]].price > 0) {
                    delete order_place[from][ids[0]];
                }
            }
            IERC1155Upgradeable(_conAddr).safeTransferFrom(
                from,
                msg.sender,
                ids[0],
                ids[2],
                ""
            );
        }
    }

    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType, isd[4] - collectionId
    function acceptBId(
        string memory bidtoken,
        address bidaddr,
        uint256[] memory ids,
        address _conAddr
    ) public {
        _acceptBId(bidtoken, bidaddr, owner(), ids, _conAddr);
        if (ids[3] == 721) {
            IERC721Upgradeable(_conAddr).safeTransferFrom(
                msg.sender,
                bidaddr,
                ids[0]
            );
                if (order_place[msg.sender][ids[0]].price > 0) {
                    delete order_place[msg.sender][ids[0]];
                }
        } else {
            if (
                IERC1155Upgradeable(_conAddr).balanceOf(msg.sender, ids[0]).sub(ids[2]) == 0
            ) {
                if (order_place[msg.sender][ids[0]].price > 0) {
                    delete order_place[msg.sender][ids[0]];
                }
            }
            IERC1155Upgradeable(_conAddr).safeTransferFrom(
                msg.sender,
                bidaddr,
                ids[0],
                ids[2],
                ""
            );
            
        }
    }
    // ids[0] - tokenId, ids[1] - amount, ids[2] -  nooftoken, ids[3] - nftType
    //ldatas[0] = _royal, ldatas[1] = Tokendecimals, ldatas[2] = approveValue, ldatas[3] = _adminfee,
    //ldatas[4] = roy, ldatas[5] = netamount, ldatas[6] = val
    function _acceptBId(
        string memory tokenAss,
        address from,
        address admin,
        uint256[] memory ids,
        address _conAddr
    ) internal {
        uint256[7] memory ldatas;
        ldatas[6] = pERCent(ids[1], serviceValue).add(ids[1]);
        address create;
                if(lazy721    ==  _conAddr || lazy1155    ==  _conAddr){
                    if (ids[3] == 721) {
            (create, ldatas[0]) = LazyCollective721(lazy721)
                .getCreatorsAndRoyalty(ids[0]);
        } else {
            (create, ldatas[0]) = LazyCollective1155(lazy1155)
                .getCreatorsAndRoyalty(ids[0]);
        }
                }
        IERC20Upgradeable t = IERC20Upgradeable(tokentype[tokenAss]);
        ldatas[1] = deci.sub(t.decimals());
        ldatas[2] = t.allowance(from, address(this));
        (ldatas[3], ldatas[4], ldatas[5]) = calc(
            ids[1],
            ldatas[0],
            serviceValue,
            sellervalue
        );
        if (ldatas[3] != 0) {
            t.transferFrom(from, admin, ldatas[3].div(10**ldatas[1]));
        }
        if (ldatas[4] != 0) {
            t.transferFrom(from, create, ldatas[4].div(10**ldatas[1]));
        }
        if (ldatas[5] != 0) {
            t.transferFrom(from, msg.sender, ldatas[5].div(10**ldatas[1]));
        }
    }
    function minting(
        string[] memory ipfsmetadata,
        address[] memory users,
        uint256[] memory datas
    ) internal {
        require(
            msg.sender == owner() || publicMint == true,
            "Public Mint Not Available"
        );
        _tid = _tid.add(1);
        uint256 id_ = _tid.add(block.timestamp);
        // _setRoyalty(_splitpercentage, splitaddress, datas[2], id_);
        if (datas[1] == 721) {
            LazyCollective721(lazy721).mint(
                ipfsmetadata[0],
                users[0],
                users[1],
                datas[2],
                id_,
                ipfsmetadata[2]
            );
            if (datas[3] > 0) {
                orderPlace(id_, datas[3], lazy721, users[0], datas[1], ipfsmetadata[2]);
            } else {
                emit OrderPlace(msg.sender, id_, datas[3]);
            }
        } else {
           if(keccak256(abi.encodePacked((ipfsmetadata[4]))) ==
            keccak256(abi.encodePacked(("tickets")))){
                LazyCollective1155(lazyTicket1155).mint(
                ipfsmetadata[0],
                users[0],
                users[1],
                datas[0],
                datas[4],
                datas[2],
                id_
            );
            }
            else{
                LazyCollective1155(lazy1155).mint(
                ipfsmetadata[0],
                users[0],
                users[1],
                datas[0],
                datas[4],
                datas[2],
                id_
            );
            }
            if (datas[3] > 0) {
                 if (
            keccak256(abi.encodePacked((ipfsmetadata[2]))) ==
            keccak256(abi.encodePacked(("lazy"))) && datas[0] != datas[4] 
        ) {
             orderPlace(
                    id_,
                    datas[3].div(datas[0]),
                    lazy1155,
                    users[0],
                    datas[1],
                    ipfsmetadata[2]
                );

        }
        else{
             orderPlace(
                    id_,
                    datas[3],
                    lazy1155,
                    users[0],
                    datas[1],
                    ipfsmetadata[2]
                );

        }
               
            } else {
                emit OrderPlace(msg.sender, id_, datas[3]);
            }
        }
        emit Create(users[0], users[1], id_, ipfsmetadata[1]);
    }

    // ipfsmetadata[0] - meta, ipfsmetadata[1] - datas, ipfsmetadata[2] - status, ipfsmetadata[3] - _message, ipfsmetadata[4] - (value) other
    // users[0] - from, users[1] - to
    // datas[0] - supply, datas[1] - nftType, datas[2] -  royal, datas[3] - price, datas[4] - total, datas[5] - _nonce, datas[6] - signatureValue
    // _nonce - per Signature private Key 
    function lazyMint(
        string[] memory ipfsmetadata,
        address[] memory users,
        uint256[] memory datas,
        string memory bidtoken,
        bytes memory signature
    ) public payable {
        require(verify(users[0], datas[6], ipfsmetadata[3], datas[5], signature) == true || verify(users[1], datas[6], ipfsmetadata[3], datas[5], signature) == true,"Not vaild User");
        minting(ipfsmetadata, users, datas);
        transfersaleToken(users, datas[3], 721, 0, bidtoken);
    }
    // ipfsmetadata[0] - meta, ipfsmetadata[1] - datas, ipfsmetadata[2] - status, ipfsmetadata[3] - _message, ipfsmetadata[4] - (value)tickets or transfer
    // users[0] - from, users[1] - to, users[2] - creator
    // datas[0] - supply, datas[1] - nftType, datas[2] -  royal, datas[3] - price, datas[4] - total, datas[5] - _nonce, datas[6] - signatureValue, datas[7] - tokenId
    // _nonce - per Signature private Key 
    function ticketMinting(
        string[] memory ipfsmetadata,
        address[] memory users,
        uint256[] memory datas,
        string memory bidtoken,
        bytes memory signature
        ) public payable{
            require(verify(users[0], datas[6], ipfsmetadata[3], datas[5], signature) == true || verify(users[1], datas[6], ipfsmetadata[3], datas[5], signature) == true,"Not vaild User");
            if(datas[7] == 0){
                minting(ipfsmetadata, users, datas);
            }
            else{
                mintingAndBurn(ipfsmetadata, users, datas);
            }
            if(keccak256(abi.encodePacked((ipfsmetadata[4]))) !=
            keccak256(abi.encodePacked(("transfer")))){
                transfersaleToken(users, datas[3], 721, 0, bidtoken);
            }
        }

    function mintingAndBurn(
        string[] memory ipfsmetadata,
        address[] memory users,
        uint256[] memory datas
    ) internal {
        _tid = _tid.add(1);
        uint256 id_ = _tid.add(block.timestamp);
        LazyCollective1155(lazyTicket1155).mintAndBurn(
                ipfsmetadata[0],
                users[0],
                users[1],
                users[2],
                datas[0],
                datas[2],
                id_,
                datas[7]
            );
            
            if (datas[3] > 0) {
                 if (
            keccak256(abi.encodePacked((ipfsmetadata[2]))) ==
            keccak256(abi.encodePacked(("lazy"))) && datas[0] != datas[4] 
        ) {
             orderPlace(
                    id_,
                    datas[3].div(datas[0]),
                    lazy1155,
                    users[0],
                    datas[1],
                    ipfsmetadata[2]
                );
        }
        else{
             orderPlace(
                    id_,
                    datas[3],
                    lazy1155,
                    users[0],
                    datas[1],
                    ipfsmetadata[2]
                );

        }  
            } else {
                emit OrderPlace(msg.sender, id_, datas[3]);
            }
        
        emit Create(users[0], users[1], id_, ipfsmetadata[1]);
    }

    function transfersaleToken(
        address[] memory users,
        uint256 datas,
        uint _type,
        uint _id,
        string memory bidtoken
    ) internal {
        uint256[7] memory ldatas;
        address create;
        ldatas[6] = pERCent(datas, serviceValue).add(datas);
        if(_type == 721){
            ldatas[0] = 0;
        }
        else{
            (create, ldatas[0]) = LazyCollective1155(lazy1155)
                .getCreatorsAndRoyalty(_id);
        }
        if (
            keccak256(abi.encodePacked((bidtoken))) ==
            keccak256(abi.encodePacked(("Coin")))
        ) {
            require(msg.value == ldatas[6], "Mismatch the msg.value");
            (ldatas[3], ldatas[4], ldatas[5]) = calc(
                datas,
                ldatas[0],
                serviceValue,
                sellervalue
            );
            require(
                msg.value == ldatas[3].add(ldatas[4].add(ldatas[5])),
                "Missmatch the fees amount"
            );
            if (ldatas[3] != 0) {
                payable(owner()).transfer(ldatas[3]);
            }
            if (ldatas[4] != 0) {
                payable(create).transfer(ldatas[4]);
            }
            if (ldatas[5] != 0) {
                payable(users[0]).transfer(ldatas[5]);
            }
        } else {
            IERC20Upgradeable t = IERC20Upgradeable(tokentype[bidtoken]);
            ldatas[1] = deci.sub(t.decimals());
            ldatas[2] = t.allowance(users[1], address(this)); 
            (ldatas[3], ldatas[4], ldatas[5]) = calc( 
                datas,
                0,
                serviceValue,
                sellervalue
            );
            if (ldatas[3] != 0) {
                t.transferFrom(users[1], owner(), ldatas[3].div(10**ldatas[1]));
            }

            if (ldatas[5] != 0) {
                t.transferFrom(
                    users[1],
                    users[0],
                    ldatas[5].div(10**ldatas[1])
                );
            }
        }
    }

    function enablePublicMint() public onlyOwner {
        publicMint = true;
    }

    function disablePublicMint() public onlyOwner {
        publicMint = false;
    }

    function setCollectionAddress(address _ERC721, address _ERC1155, address _lazyTicket1155)
        public
        onlyOwner
    {
        lazy721 = _ERC721;
        lazy1155 = _ERC1155;
        lazyTicket1155 = _lazyTicket1155;
    }
    function openUri(bool open) public onlyOwner {
        LazyCollective721(lazy721)._openUri(open);
        LazyCollective1155(lazy1155)._openUri(open);
        LazyCollective1155(lazyTicket1155)._openUri(open);
    }

    function _transferNFT(
        address[] memory users,
        uint256 tokenid,
        uint256 count,
        uint256 amount,
        string memory bidtoken
    ) public payable{
        if (
            keccak256(abi.encodePacked((bidtoken))) ==
            keccak256(abi.encodePacked(("Coin")))
        ) {
            require(
                amount == order_place[users[0]][tokenid].price.mul(count) &&
                    order_place[users[0]][tokenid].price.mul(count) > 0,
                "Order Mismatch"
            );
        }
        
        LazyCollective1155(lazy1155).TransferNFT(users[1], tokenid, count);
        transfersaleToken(users, amount, 1155, tokenid, bidtoken);
    }

    function changeCollectionOwner(address to) public {
        LazyCollective721(lazy721).changeCollectionOwner(to);
        LazyCollective1155(lazy1155).changeCollectionOwner(to);
    }
    function nftTransfer(uint256 tokenId, address to, uint count) public {
        address create;
        uint256 roy;
        (create, roy) = LazyCollective1155(lazy1155)
                .getCreatorsAndRoyalty(tokenId);
        
        require(create == msg.sender && IERC1155Upgradeable(lazy1155).balanceOf(address(this),tokenId) >= count ,"Not a Owner");
        IERC1155Upgradeable(lazy1155).safeTransferFrom(
                address(this),
                to,
                tokenId,
                count,
                ""
            );
    }
    function SetRoyalty(uint96 _royPer) public onlyOwner{
        LazyCollective721(lazy721).setRoyaltyPercentage(_royPer);
        LazyCollective1155(lazy1155).setRoyaltyPercentage(_royPer);
    }
}