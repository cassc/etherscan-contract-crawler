// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

contract ClaimContract is IERC721ReceiverUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    uint256 private factor;

    uint256[][] public listNFTid; // useless

    IERC20Upgradeable public NINOToken;
    IERC20Upgradeable public MATAToken;
    IERC721Upgradeable public neko;

    bool public paused;
    address public validator;
    mapping(address => mapping(uint256 => uint256)) lastClaims;

    uint256 public requestExpire;
    uint256 public claimGap;
    address public operator;

    uint256 public mataMaterialId;
    uint256 public ninoMaterialId;

    // 600654: 0-Wild Pet (Sapphire Box)
    // 600658: 1-Wild Pet (Cotton Box)
    // 600662: 2-Wild Pet
    // 600663: 3-Wild Pet
    // 600664: 1-Wild Pet X1
    // 600665: 2-Wild Pet X1 + Random
    mapping(uint256 => uint256[][]) public nftListMap; // materialId => [ [nft11, nft12, nft13], [nft21, nft22] ]

    event SetPaused(bool);
    event SetValidator(address);

    event EventRefClaimNino(uint256 indexed eventId, address indexed addr, uint256 amount);
    event ClaimMaterial(address indexed addr, uint256 indexed materialId, uint256 amount);

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == owner(), "Not the operator or owner");
        _;
    }

    function initialize(
        address _nino,
        address _mata,
        address _neko
    ) public initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        validator = owner();
        requestExpire = 5 minutes;
        claimGap = 1 days; // claimGap must be greater than requestExpire
        NINOToken = IERC20Upgradeable(_nino);
        MATAToken = IERC20Upgradeable(_mata);
        neko = IERC721Upgradeable(_neko);
    }

    function addListNFTId(uint256[] memory _listNFTid) external onlyOwner {
        listNFTid.push(_listNFTid);
    }

    function setListNFTId(uint256 _index, uint256[] memory _listNFTid) external onlyOwner {
        listNFTid[_index] = _listNFTid;
    }

    function removeListNFTId(uint256 _index) external onlyOwner {
        listNFTid[_index] = listNFTid[listNFTid.length - 1];
        listNFTid.pop();
    }

    function addNftListMap(uint256 materialId, uint256[] memory array) external onlyOwner {
        nftListMap[materialId].push(array);
    }

    function setNftListMap(
        uint256 materialId,
        uint256 idx,
        uint256[] memory array
    ) external onlyOwner {
        nftListMap[materialId][idx] = array;
    }

    function removeNftListMap(uint256 materialId, uint256 idx) external onlyOwner {
        nftListMap[materialId][idx] = nftListMap[materialId][nftListMap[materialId].length - 1];
        nftListMap[materialId].pop();
    }

    function changeMaterialIds(uint256 _mataMaterialId, uint256 _ninoMaterialId) external onlyOwner {
        if (_mataMaterialId > 0) mataMaterialId = _mataMaterialId;
        if (_ninoMaterialId > 0) ninoMaterialId = _ninoMaterialId;
    }

    function setPause(bool _pause) external onlyOwner {
        paused = _pause;
        emit SetPaused(paused);
    }

    function setValidator(address _validator) external onlyOwner {
        validator = _validator;
        emit SetValidator(_validator);
    }

    function setRequestExpire(uint256 _timer) external onlyOwner {
        requestExpire = _timer;
    }

    function setClaimGap(uint256 _timer) external onlyOwner {
        claimGap = _timer;
    }

    function lastClaim(address _addr, uint256 _type) external view returns (uint256) {
        return lastClaims[_addr][_type];
    }

    function setOperator(address _address) public onlyOwner {
        operator = _address;
    }

    function eventRefClaimNino(
        string memory _eventId,
        string memory _amount,
        uint256 _nonce,
        bytes memory _sign
    ) external whenNotPaused nonReentrant {
        uint256 _now = block.timestamp;
        address _user = msg.sender;
        uint256 _eventIdInt = stringToUint(_eventId);
        uint256 _amountInt = stringToUint(_amount);
        require(_nonce <= _now && _now <= _nonce + requestExpire, "Claim request expired");
        require(lastClaims[_user][_eventIdInt] == 0, "Claimed already");
        require(validSign(msg.sender, _eventId, _amount, _nonce, _sign), "Invalid sign");
        NINOToken.transfer(_user, _amountInt);
        emit EventRefClaimNino(_eventIdInt, _user, _amountInt);
    }

    function claimMaterial(
        string memory _materialId,
        string memory _amount,
        uint256 _nonce,
        bytes memory _sign
    ) external whenNotPaused nonReentrant {
        uint256 _now = block.timestamp;
        address _user = msg.sender;
        uint256 _materialIdInt = stringToUint(_materialId);
        uint256 _amountInt = stringToUint(_amount);
        require(_nonce <= _now && _now <= _nonce + requestExpire, "Claim request expired");
        require(_now >= lastClaims[_user][_materialIdInt] + claimGap, "Your claim is not in due time yet");
        require(validSign(msg.sender, _materialId, _amount, _nonce, _sign), "Invalid sign");

        if (_materialIdInt == mataMaterialId) {
            // MATA
            MATAToken.transfer(_user, _amountInt * 1_000_000_000_000_000_000);
        } else if (_materialIdInt == ninoMaterialId) {
            // NINO
            NINOToken.transfer(_user, _amountInt * 1_000_000_000_000_000_000);
        } else {
            // NFT
            uint256[][] storage arrays = nftListMap[_materialIdInt];
            for (uint256 _t = 0; _t < _amountInt; _t++) {
                uint256 totalNft;
                for (uint256 i = 0; i < arrays.length; i++) {
                    totalNft = totalNft + arrays[i].length;
                }
                require(totalNft > 0, "Insufficient NFT left in contract");
                uint256 index = random(totalNft);
                uint256 nftId = _getNftId(index, arrays);
                require(nftId > 0, "Get NFT ID failed");
                neko.transferFrom(address(this), _user, nftId);
            }
        }

        lastClaims[_user][_materialIdInt] = _now;
        emit ClaimMaterial(_user, _materialIdInt, _amountInt);
    }

    function _getNftId(uint256 _index, uint256[][] storage arrays) private returns (uint256) {
        uint256 preTotal = 0;
        uint256 curTotal = 0;
        for (uint256 i = 0; i < arrays.length; i++) {
            if (arrays[i].length > 0) {
                preTotal = curTotal;
                curTotal = curTotal + arrays[i].length;
                if (_index == 0 || _index < curTotal) {
                    uint256 nftIndex = 0;
                    if (_index == 0 || i == 0) {
                        nftIndex = _index;
                    } else {
                        nftIndex = _index - preTotal;
                    }
                    uint256 nftId = arrays[i][nftIndex];
                    arrays[i][nftIndex] = arrays[i][arrays[i].length - 1];
                    arrays[i].pop();
                    return nftId;
                }
            }
        }
        return 0;
    }

    function stringToUint(string memory s) private pure returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function validSign(
        address addr,
        string memory s1,
        string memory s2,
        uint256 nonce,
        bytes memory sign
    ) private view returns (bool) {
        bytes32 _hash = keccak256(abi.encodePacked(addr, s1, s2, nonce));
        _hash = _hash.toEthSignedMessageHash();
        address _signer = _hash.recover(sign);
        return _signer == validator;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function random(uint256 _modulus) public returns (uint256) {
        factor++;
        return uint256(keccak256(abi.encodePacked(factor, block.difficulty, block.timestamp, msg.sender))) % _modulus;
    }

    function recoverNonFungibleToken(uint256[] memory _listTokenId) external onlyOwner {
        for (uint256 i = 0; i < _listTokenId.length; i++) {
            uint256 tokenId = _listTokenId[i];
            neko.transferFrom(address(this), address(msg.sender), tokenId);
        }
    }

    function recoverToken(address _token) external onlyOwner {
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(balance > 0, "Operations: Cannot recover zero balance");
        IERC20Upgradeable(_token).transfer(address(msg.sender), balance);
    }

    receive() external payable {}

    function recoverBNB() public onlyOwner {
        (bool recover, ) = owner().call{value: address(this).balance}("");
        require(recover, "RecoverBNB error");
    }
}