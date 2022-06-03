// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interface/IAdapter.sol";

contract XAirDrop is Initializable, IERC721ReceiverUpgradeable, IERC1155ReceiverUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct AirDrop{
        bool isListed;
        uint256 ercType;
        address airDropTokenContract;
        address airDropContract;
        string method;
        IAdapter adapter;
    }

    bool internal _notEntered;

    address public xNFT;
    address public admin;
    address public pendingAdmin;

    // NFT contract => airdrop contract => struct
    mapping(address => mapping(address => AirDrop)) public erc20Map;
    // NFT contract => airdrop contract => tokenId
    mapping(address => mapping(address => mapping(uint256 => bool))) isClaim20AirDropMap;
    // NFT contract => airdrop contract => struct
    mapping(address => mapping(address => AirDrop)) public erc721Map;
    // NFT contract => airdrop contract => tokenId
    mapping(address => mapping(address => mapping(uint256 => bool))) isClaim721AirDropMap;
    // NFT contract => airdrop contract => struct
    mapping(address => mapping(address => AirDrop)) public erc721aMap;
    // NFT contract => airdrop contract => tokenId
    mapping(address => mapping(address => mapping(uint256 => bool))) isClaim721aAirDropMap;

    function initialize(address _xNFT) external initializer {
        xNFT = _xNFT;
        admin = msg.sender;
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "require admin auth");
        _;
    }

    modifier onlyERC(uint256 ercType) {
        require(ercType == 20 || ercType == 721 || ercType == 72110, "ercType is error");
        _;
    }

    function setPendingAdmin(address newPendingAdmin) external onlyAdmin{
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public{
        require(msg.sender == pendingAdmin, "only pending admin could accept");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setXNFT(address _xNFT) external onlyAdmin{
        xNFT = _xNFT;
    }

    function addERC(address nftContract, bool _isListed, uint256 _ercType, address _airDropTokenContract, address _airDropContract, string memory _method, IAdapter _adapter) external onlyERC(_ercType) onlyAdmin{
        AirDrop storage airDrop;
        if(_ercType == 20){
            airDrop = erc20Map[nftContract][_airDropContract];
            airDrop.ercType = 20;
        }else if(_ercType == 721){
            airDrop = erc721Map[nftContract][_airDropContract];
            airDrop.ercType = 721;
        }else{ // 721a
            airDrop = erc721aMap[nftContract][_airDropContract];
            airDrop.ercType = 72110;
        }
        require(airDrop.airDropTokenContract == address(0), "already assigned value");
        airDrop.isListed = _isListed;
        airDrop.airDropTokenContract = _airDropTokenContract;
        airDrop.airDropContract = _airDropContract;
        airDrop.method = _method;
        airDrop.adapter = _adapter;
    }

    function setERC(address nftContract, bool _isListed, uint256 _ercType, address _airDropTokenContract, address _airDropContract, string memory _method, IAdapter _adapter) external onlyERC(_ercType) onlyAdmin{
        AirDrop storage airDrop;
        if(_ercType == 20){
            airDrop = erc20Map[nftContract][_airDropContract];
        }else if(_ercType == 721){
            airDrop = erc721Map[nftContract][_airDropContract];
        }else{ // 721a
            airDrop = erc721aMap[nftContract][_airDropContract];
        }
        require(airDrop.airDropTokenContract != address(0), "no value has been assigned");
        airDrop.isListed = _isListed;
        airDrop.airDropTokenContract = _airDropTokenContract;
        airDrop.method = _method;
        airDrop.adapter = _adapter;
    }

    function execution(address nftContract, address airDropContract, address receiver, uint256 tokenId, uint256 ercType) external  onlyERC(ercType) nonReentrant{
        require(msg.sender == xNFT, "not xNFT");
        IERC721Upgradeable(nftContract).setApprovalForAll(xNFT, true);
        if(ercType == 20){
            erc20(nftContract, airDropContract, receiver, tokenId);
        }else if(ercType == 721){
            erc721(nftContract, airDropContract, receiver, tokenId);
        }else if(ercType == 72110){ // 721a
            erc721a(nftContract, airDropContract, receiver, tokenId);
        }
    }

    function erc20(address nftContract, address airDropContract, address receiver, uint256 tokenId) internal{
        AirDrop memory airDrop = erc20Map[nftContract][airDropContract];
        if(airDrop.ercType == 20 && airDrop.isListed == true){
            (bool result, ) = airDrop.airDropContract.call(airDrop.adapter.getByteCodeERC20(nftContract, airDrop.method, airDrop.airDropTokenContract, receiver, tokenId));
            require(result, "20 call execution failed");
            uint256 airdropBalance = IERC20Upgradeable(airDrop.airDropTokenContract).balanceOf(address(this));
            if (airdropBalance > 0) {
                IERC20Upgradeable(airDrop.airDropTokenContract).safeTransfer(receiver, airdropBalance);

                isClaim20AirDropMap[nftContract][airDropContract][tokenId] = true;
            }
        }
    }

    function erc721(address nftContract, address airDropContract, address receiver, uint256 tokenId) internal{
        AirDrop memory airDrop = erc721Map[nftContract][airDropContract];
        if(airDrop.ercType == 721 && airDrop.isListed == true){
            (bool result, ) = airDrop.airDropContract.call(airDrop.adapter.getByteCodeERC721(nftContract, airDrop.method, airDrop.airDropTokenContract, receiver, tokenId));
            require(result, "721 call execution failed");
            IERC721EnumerableUpgradeable ierc721 = IERC721EnumerableUpgradeable(airDrop.airDropTokenContract);
            uint256 airdropBalance = ierc721.balanceOf(address(this));
            if(airdropBalance > 0){
                for(uint256 i=0; i<airdropBalance; i++){
                    uint256 _tokenId = ierc721.tokenOfOwnerByIndex(address(this), 0);
                    ierc721.safeTransferFrom(address(this), receiver, _tokenId);
                }
                isClaim721AirDropMap[nftContract][airDropContract][tokenId] = true;
            }
        }
    }

    function erc721a(address nftContract, address airDropContract, address receiver, uint256 tokenId) internal{
        AirDrop memory airDrop = erc721aMap[nftContract][airDropContract];
        if(airDrop.ercType == 72110 && airDrop.isListed == true){
            IERC721EnumerableUpgradeable ierc721 = IERC721EnumerableUpgradeable(airDrop.airDropTokenContract);
            uint256 erc721aTotalSupplyBefore = ierc721.totalSupply();

            (bool result, ) = airDrop.airDropContract.call(airDrop.adapter.getByteCodeERC721(nftContract, airDrop.method, airDrop.airDropTokenContract, receiver, tokenId));
            require(result, "721a call execution failed");

            uint256 erc721aTotalSupplyAfter = ierc721.totalSupply();
            if((erc721aTotalSupplyAfter - erc721aTotalSupplyBefore) > 0){
                for(uint256 i=erc721aTotalSupplyBefore; i<erc721aTotalSupplyAfter; i++){
                    ierc721.safeTransferFrom(address(this), receiver, i);
                }
                isClaim721aAirDropMap[nftContract][airDropContract][tokenId] = true;
            }
        }
    }

    function getIsClaim20AirDropMap(address nftContracts, address airdropContracts, uint256[] memory tokenIds) external view returns(bool[] memory isClaims){
        isClaims = new bool[](tokenIds.length);
        for(uint256 i=0; i<tokenIds.length; i++){
            isClaims[i] = isClaim20AirDropMap[nftContracts][airdropContracts][tokenIds[i]];
        }
    }

    function getIsClaim721AirDropMap(address nftContracts, address airdropContracts, uint256[] memory tokenIds) external view returns(bool[] memory isClaims){
        isClaims = new bool[](tokenIds.length);
        for(uint256 i=0; i<tokenIds.length; i++){
            isClaims[i] = isClaim721AirDropMap[nftContracts][airdropContracts][tokenIds[i]];
        }
    }

    function getIsClaim721aAirDropMap(address nftContracts, address airdropContracts, uint256[] memory tokenIds) external view returns(bool[] memory isClaims){
        isClaims = new bool[](tokenIds.length);
        for(uint256 i=0; i<tokenIds.length; i++){
            isClaims[i] = isClaim721aAirDropMap[nftContracts][airdropContracts][tokenIds[i]];
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4){
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns (bytes4){
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived( address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool){
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId;
    }
}