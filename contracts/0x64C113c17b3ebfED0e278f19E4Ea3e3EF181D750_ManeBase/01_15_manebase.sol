// contracts/nftclub.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "../operator-filter-registry/src/DefaultOperatorFilterer.sol";


// Share configure
struct TShare {
    address owner;
    uint256 ratioPPM;
}

abstract contract ERC721AM is ERC721A {
    mapping(address => uint256[]) public tokenIDByHolder;

    // Override the _transfer function to record holders
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);
        updateHolderInfo(from, to, tokenId);
    }

    function updateHolderInfo(address from, address to, uint256 tokenId) internal {
        tokenIDByHolder[to].push(tokenId);
        for (uint256 i = 0; i < tokenIDByHolder[from].length; i++) {
            if (tokenIDByHolder[from][i] == tokenId) {
                tokenIDByHolder[from][i] = tokenIDByHolder[from][tokenIDByHolder[from].length - 1];
                tokenIDByHolder[from].pop();
                break;
            }
        }
    }
}


contract ManeBase is ERC721AM, Ownable, DefaultOperatorFilterer {
    // Mint price in sale period
    uint256 public _salePrice;
    
    address public factory;
    
    uint256 public platformBalance;
    uint256 public ownerBalance;
    uint256 public collectorBalance;

    uint256 private _reserveQuantity;

    // Max number allow to mint
    uint256 public _maxSupply;
  
    // Presale and Publicsale start time
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public saleStartTime;
    uint256 public saleEndTime;

    // Presale Mintable Number
    uint256 public presaleMaxSupply = 0;
    uint256 public presaleMintedCount = 0;

    // Mint count per address
    mapping(address => uint256) public presaleMintCountByAddress;
    uint256 public presaleMaxMintCountPerAddress;

    mapping(address => uint256) public saleMintCountByAddress;
    uint256 public saleMaxMintCountPerAddress;

    // Platform fee ratio in PPM
    uint256 public platformFeePPM = 0;

    // Super admin is able to set isForceRefundable flag to true in 7 days since the first token was minted in the public sale period or all tokens were minted in the presale period.
    // When isForceRefundable is set to true, token holders can get a full refund in 7 days.
    // Neither Creators nor platform is also not allowed to withdraw in 7 days when isForceRefundable is set to true.
    uint256 public isForceRefundable = 0;
    uint256 public forceRefundDeadline = 2**32;

    // Is the contract paused
    uint256 public paused = 0;


    //event TokenMinted(address minter, uint256 tokenId , uint256 mintPrice, uint256 platformFee);
    
    //event ContractDeployed(address sender, address contract_address, uint256 reserveQuantity, uint256 clubId);


    // Mint Information
    // mapping(tokenID => TMintInfO)
    struct TMintInfo {
        uint256 isPreMint;
        uint256 isRefunded;
        //address minter;
        uint256 price;
    }
    mapping(uint256 => TMintInfo) public _mintInfo;

    // Refund Times and Ratios
    struct TRefundTime {
        uint256 endTime;        /// Refund is available before this time (and isRefundable == true). In unix timestamp.
        uint256 ratioPPM;       /// How much ratio can be refund
    }

    
    // Share list
    TShare[] public _shareList;

    // Refund Time List    
    TRefundTime[] public _refundTimeList;

    /**
    u256[0] =>  reserveQuantity
        [1] =>  maxSupply
        [2] =>  presaleMaxSupply
        [3] =>  clubID              (obsoleted)
        [4] =>  presaleStartTime
        [5] =>  presaleEndTime
        [6] =>  saleStartTime
        [7] =>  saleEndTime
        [8] =>  presalePrice        (obsoleted)
        [9] =>  salePrice
        /// How many tokens a wallet can mint
        [10] => presalePerWalletCount
        [11] => salePerWalletCount
        [12] => signature nonce
    */ 
    constructor(string memory name_, string memory symbol_, uint256[] memory u256s,
                address[] memory shareAddresses_, uint256[] memory shareRatios_, uint256[] memory refundTimes_, uint256[] memory refundRatios_
            ) ERC721A(name_, symbol_) {   
        require(u256s[0] + u256s[2] <= u256s[1], "MB:maxSupply");


        // 1. Deplay and log the create event
        factory = msg.sender;

        _reserveQuantity = u256s[0];
        presaleMaxSupply = u256s[2];
        setPresaleTimes(u256s[4], u256s[5]);
        setSaleTimes(u256s[6], u256s[7]);
        setMintPrice(u256s[9]);
        _maxSupply = u256s[1];

        transferOwnership(tx.origin);

        //emit ContractDeployed(tx.origin, address(this), u256s[0], u256s[3]);

        /// 2. Reserve tokens for creator
        initReserve(u256s[0]);

        /// 3. Setting share list

        // To reduce contract size, share list is no longer available
        shareAddresses_;
        shareRatios_;
        // uint256 totalShareRatios = 0;
        // for (uint256 i = 0; i < shareAddresses_.length; i++) {
        //     TShare memory t;
        //     t.owner = shareAddresses_[i];
        //     t.ratioPPM = shareRatios_[i];

        //     totalShareRatios += t.ratioPPM;

        //     _shareList.push(t);
        // }
        // require(totalShareRatios <= 1 * 1000 * 1000, "MB:shareRatios of");

        /// 4. Setting refund times
        require(refundTimes_.length == refundRatios_.length, "MB:len mismatch");
        uint256 oldEndTime = 0;
        uint256 oldRatio = 1e9;
        for( uint256 i = 0; i < refundTimes_.length; i++) {
            TRefundTime memory t;
            t.endTime = refundTimes_[i];
            t.ratioPPM = refundRatios_[i];

            require(t.endTime > oldEndTime, "MB:refundTimes inval");
            require(t.ratioPPM < oldRatio, "MB:refundRatio inval");

            oldEndTime = t.endTime;
            oldRatio = t.ratioPPM;

            _refundTimeList.push(t);
        }
        

        /// 5. Setting mint limit for wallets
        presaleMaxMintCountPerAddress = u256s[10];
        saleMaxMintCountPerAddress = u256s[11];
        unchecked{
            if (presaleMaxMintCountPerAddress == 0) {
                presaleMaxMintCountPerAddress -= 1;
            }
            if (saleMaxMintCountPerAddress == 0) {
                saleMaxMintCountPerAddress -= 1;
            }
        }

        /// 6. Setting platform PPM
        platformFeePPM = ManeFactory(factory).platformFeePPM();
    }

    function initReserve(uint256 reserveQuantity) private {
        if (reserveQuantity > 0) {
            uint256 currentIndex = _currentIndex;
            _mint(tx.origin, reserveQuantity, "", false);
            for (uint256 i = currentIndex; i < currentIndex + reserveQuantity; i++) {
                //emit TokenMinted(tx.origin, i, 0, 0);
                tokenIDByHolder[tx.origin].push(i);
            }
        }
    }


    function getAll() public view returns (uint256[] memory) {
        uint256[] memory u = new uint256[](12);
       
        u[0] = _reserveQuantity;
        u[1] = _maxSupply;
        u[2] = presaleMaxSupply;
        // u[3] = clubId;   // (obsoleted)
        u[4] = presaleStartTime;
        u[5] = presaleEndTime;
        u[6] = saleStartTime;
        u[7] = saleEndTime;
        // u[8] = 0;       // (obsoleted)
        u[9] = _salePrice;
        // u[10] = presaleMaxMintCountPerAddress;       // Shrink contract size
        // u[11] = saleMaxMintCountPerAddress;          // Shrink contract size

        return (u);
    }
    
    // Minted token will be sent to minter
    // sign_deadline, r, s, v is only require at presale perioid. These parameters are server-side signature data.
    function mint(address minter, uint256 mint_price, uint256 count, uint256 sign_deadline, bytes32 r, bytes32 s, uint8 v) payable whenNotPaused public {
        uint256 isPresale = 0;
        uint256 isSale = 0;

        // 0. Check is mintable
        if (block.timestamp < presaleStartTime) {
            // Period: Sale not started
            revert("MB:Not started");
        } else if (block.timestamp >= presaleStartTime && block.timestamp < presaleEndTime) {
            // Period: Pre-sale period
            require(msg.value >= mint_price * count, "MB:presale val");
            isPresale = 1;
        } else if (block.timestamp >= saleStartTime && block.timestamp <= saleEndTime) {
            // Period: Public sale perild
            require(mint_price == _salePrice, "MB:mint_price");
            require(msg.value >= _salePrice * count, "MB:sale val");
            isSale = 1;
        } else {
            revert("MB:Inval period");
        }

        /// Mint `count` number of tokens
        for (uint256 i = 0; i < count; i++) {
            require(totalMinted() < _maxSupply, "MB:No more");

            if (isPresale == 1) {
                requireMintSign(minter, mint_price, count, sign_deadline, r, s, v);

                presaleMintedCount++;
                require(presaleMintedCount <= presaleMaxSupply, "MB:Exceed");
                
                presaleMintCountByAddress[msg.sender]++;
                require(presaleMintCountByAddress[msg.sender] <= presaleMaxMintCountPerAddress, "MB:addr(A)");
            } else if (isSale == 1) {
                //requireMintSign(minter, mint_price, sign_deadline, r, s, v);

                saleMintCountByAddress[msg.sender]++;
                require(saleMintCountByAddress[msg.sender] <= saleMaxMintCountPerAddress, "MB:addr(B)");
                
            } else {
                revert("MB:NotSalePeriod");
            }


            // 1. Mint it
            uint256 currentIndex = _currentIndex;

            _mint(minter, 1, "", false);
            tokenIDByHolder[minter].push(currentIndex);


            // 2. Send mint value to creator and platform and collectors
            uint256 platformGot = mint_price * platformFeePPM / 1e6;
            uint256 collectorGot = (mint_price - platformGot) * getCollectorTotalRatioPPM() / 1e6;
            uint256 ownerGot = mint_price - platformGot - collectorGot;
            
            platformBalance += platformGot;
            collectorBalance += collectorGot;
            ownerBalance += ownerGot;

            // 4. Log events and other data
            _mintInfo[currentIndex] = TMintInfo({
                isPreMint: isPresale,
                isRefunded: 0,
                //minter: minter,
                price: mint_price
            });

            //emit TokenMinted(minter, currentIndex, mint_price, platformGot);
        }


        // Init 7-days refund time
        if (isSale == 1 || _currentIndex == _maxSupply - 1) {
            if (forceRefundDeadline == 2**32) {
                forceRefundDeadline = block.timestamp + 86400 * 7;
            }
        }
        
        //  Mint finished successfully
    }


    /// User request to refund
    function refund(uint256 tokenID) public {
        require(msg.sender == ownerOf(tokenID), "MB:owner");
        
        /// 1. Get refund ratio
        // If forceRefundable is true, holder can refund all. Otherwise holder can only refund before refund time
        uint256 refundRatioPPM = 0;
        if (isForceRefundable == 1) {
            refundRatioPPM = 1e6;
        } else {
            for (uint256 i = 0; i < _refundTimeList.length; i++) {
                if (block.timestamp < _refundTimeList[i].endTime) {
                    refundRatioPPM = _refundTimeList[i].ratioPPM;
                    break;
                }
            }
        }
        require(refundRatioPPM > 0, "MB:refundNotAvail");

        /// 2. Get mint info and check if this token is refundable
        TMintInfo storage mintInfo = _mintInfo[tokenID];
        
        require(mintInfo.isRefunded == 0, "MB:refunded");

        /// 3. Caculate the refundable value
        uint256 refundValue = mintInfo.price * refundRatioPPM / 1e6; 

        /// 4. Do refund
        uint256 platformReturn = refundValue * platformFeePPM / 1e6;
        uint256 collectorReturn = (refundValue - platformReturn) * getCollectorTotalRatioPPM() / 1e6;
        uint256 ownerReturn = refundValue - platformReturn - collectorReturn;

        platformBalance -= platformReturn;
        collectorBalance -= collectorReturn;
        ownerBalance -= ownerReturn;        

        transferFrom(msg.sender, this.owner(), tokenID);
        
        mintInfo.isRefunded = 1;

        payable(msg.sender).transfer(refundValue);
    }


    // Send shares to share holders and owner
    function collect() public onlyOwner {
        /// 1. Check if collect is open
        requireCollectable();        

        /// 2. Find the collector and transfer

        // To reduce solidity size, collector share is no longer available
        // uint256 b = collectorBalance;
        // uint256 totalRatioPPM = getCollectorTotalRatioPPM();
        // for (uint256 i = 0; i < _shareList.length; i++) {
        //     uint256 collectValue = b * _shareList[i].ratioPPM / totalRatioPPM;
        //     collectorBalance -= collectValue;
        //     payable(_shareList[i].owner).transfer(collectValue);
        // }

        /// 3. send balance to owner
        uint256 oBalance = ownerBalance;
        ownerBalance = 0;
        payable(owner()).transfer(oBalance);
    }


    // Platform (ManeStudio) collect it's shares
    function platformCollect(address to) public onlyFactoryOwner {
        requireCollectable();

        uint256 b = platformBalance;
        platformBalance = 0;
        payable(to).transfer(b);
    }

    function requireCollectable() view internal {
        for (uint256 i = 0; i < _refundTimeList.length; i++) {
            require(block.timestamp > _refundTimeList[i].endTime, "MB:refundDeadline");
        }

        /// Not allow collect in 7 days. See forceRefundDeadline for more detail
        require(block.timestamp > forceRefundDeadline, "MB:7dLimit");
        require(isForceRefundable == 0, "MB:forceRefund");
    }
    
    /// If signagure is not valid, throw exception and stop
    function requireMintSign(address minter, uint256 price, uint256 count, uint256 deadline, bytes32 r, bytes32 s, uint8 v)  internal view {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 userHash = encodeMint(minter, price, count, deadline);
        bytes32 prefixHash = keccak256(abi.encodePacked(prefix, userHash));

        address hash_address = ecrecover(prefixHash, v, r, s);

        require(hash_address == ManeFactory(factory).signerAddress(), "MB:sign");
    }


    function encodeMint( address minter, uint256 price, uint256 count, uint256 deadline) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(minter, price, count, deadline));
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function _baseURI() override internal view returns (string memory) {
        string memory factoryBaseURI = ManeFactory(factory).factoryBaseURI();
        return string(abi.encodePacked(factoryBaseURI, toString(abi.encodePacked(this)), "/"));
    }
    
    // Set the mint price for sale period
    function setMintPrice(uint256 sale_price) public onlyOwner {
        _salePrice = sale_price;
    }

    function setPresaleMaxSupply(uint256 max_) public onlyOwner {
        presaleMaxSupply = max_;
    }
    

    function adminSetRefund(uint256 is_refundable_) public onlyFactoryOwner {
        require(block.timestamp < forceRefundDeadline, "MF:time");
        isForceRefundable = is_refundable_;
    }


    function setPresaleMaxMintCountPerAddress(uint256 max_) public onlyOwner {
        presaleMaxMintCountPerAddress = max_;
    }
    function setSaleMaxMintCountPerAddress(uint256 max_) public onlyOwner {
        saleMaxMintCountPerAddress = max_;
    }

    function getCollectorTotalRatioPPM() internal view returns (uint256) {
        uint256 ratioPPM = 0;
        for (uint256 i =0; i < _shareList.length; i++) {
            ratioPPM += _shareList[i].ratioPPM;
        }

        require(ratioPPM <= 1e6, "MB:ratio");

        return ratioPPM;
    }

    function setPresaleTimes(uint256 startTime_, uint256 endTime_) public onlyOwner {
        presaleStartTime = startTime_;
        if (endTime_ == 0) {
            unchecked {
                presaleEndTime = endTime_ - 1;
            }
        } else {
            presaleEndTime = endTime_;
        }
    }

    function setSaleTimes(uint256 startTime_, uint256 endTime_) public onlyOwner {
        saleStartTime = startTime_;
        if (endTime_ == 0) {
            unchecked {
                saleEndTime = endTime_ - 1;
            }
        } else {
            saleEndTime = endTime_;
        }
    }


    // Get the token id list of the given address. If the address holds no token, empty array is return
    function getTokenIDsByHolder(address holder, uint256 offset, uint256 limit) public view returns (uint256[] memory) {
        uint256 size = tokenIDByHolder[holder].length - offset;
        if (size > limit) {
            size = limit;
        }
        uint256[] memory ret = new uint256[](size);

        for (uint256 i = 0; i < limit; i++) {
            if (i + offset >= tokenIDByHolder[holder].length) {
                break;
            } 
            ret[i] = (tokenIDByHolder[holder][i + offset]);
        }

        return ret;
    }


    function getShareListLength() public view returns (uint256) {
        return _shareList.length;
    }

    function getRefundTimeListLength() public view returns (uint256) {
        return _refundTimeList.length;
    }

    function setPaused(uint256 is_pause) public onlyOwner {
        paused = is_pause;
    }

    function destroy() public onlyOwner {
        require(_currentIndex == _reserveQuantity, "MB:notAllow");
        selfdestruct(payable(this.owner()));
    }

    modifier onlyFactoryOwner() {
        ManeFactory(factory).requireOriginIsOwner();
        _;
    }

    modifier whenNotPaused() {
        require(paused == 0, "MB:paused");
        _;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    function setOpenseaEnforcement(uint256 isEnforcement) public onlyOwner {
        openseaEnforcement = isEnforcement;
    }
}


contract SignAndOwnable is Ownable { 
    address public signerAddress;

    constructor() Ownable() {
        signerAddress = tx.origin;
    }

    // Check if the signature is valid. Returns true if signagure is valid, otherwise returns false.
    function verifySignature(bytes32 h, uint8 v, bytes32 r, bytes32 s) view internal returns (bool) {
        return (ecrecover(h, v, r, s) == signerAddress);
    }

    // Set the derived address of the public key of the signer private key
    function setSignaturePublic(address newAddress) public onlyOwner {
        signerAddress = newAddress;
    }
}


contract ManeFactory is SignAndOwnable {
    uint256 public platformFeePPM = 100 * 1e3;

    string public factoryBaseURI = "https://meta.manestudio.xyz/nft/";

    mapping(uint256 => uint256) private _usedNonces;

    // Mapping club_id => token_contract_address
    mapping(uint256 => address) public clubMap;

    constructor() SignAndOwnable() {
    }

    function deploy(string memory name_, string memory symbol_,  uint256[] memory u256s, address[] memory shareAddresses_, uint256[] memory shareRatios_, uint256[] memory refundEndTimes_, uint256[] memory refundRatios_, uint8 v, bytes32 r, bytes32 s) public returns (address) {
        /// 1. Check signagure
        bytes memory ethereum_prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 user_hash =keccak256(abi.encodePacked(ethereum_prefix, keccak256(abi.encodePacked(u256s[3], u256s[12]))));

        require(_usedNonces[u256s[12]] == 0, "MF:DupNonce");
        _usedNonces[u256s[12]] = 1;

        require(verifySignature(user_hash, v, r, s) == true, "MF:invalidSign");
        
        /// 2. Deploy contract
        ManeBase c = new ManeBase(name_, symbol_, u256s, shareAddresses_, shareRatios_, refundEndTimes_, refundRatios_);
        //contracts.push(address(c));
        clubMap[u256s[3]] = address(c);


        return address(c);
    }

    function setPlatformFeePPM(uint256 newFeePPM) public onlyOwner {
        platformFeePPM = newFeePPM;
    }

    /// Set the factoryBaseURI, must include trailing slashes
    function setFactoryBaseURI(string memory newBaseURI) public onlyOwner {
        factoryBaseURI = newBaseURI;
    }


    function requireOriginIsOwner() view public {
        require(tx.origin == owner(), "MF: NotOwner");
    }
}

function toString(bytes memory data) pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
}