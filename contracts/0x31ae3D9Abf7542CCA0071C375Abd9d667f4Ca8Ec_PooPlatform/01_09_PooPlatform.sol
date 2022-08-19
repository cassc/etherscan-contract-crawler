//SPDX-License-Identifier: <SPDX-License>
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IJOMOPoo.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/UpgradeableHelper.sol";


contract PooPlatform is Initializable, UpgradeableHelper {
    //Event
    event Rebirth(address indexed from, address indexed nftAddress, uint256[] tokenId);

    address[] whiteListNFT;
    address public platformNFTAddress;
    address public treasury;

    //Init
    function initialize(address _nftAddress, address _treasury, address[] memory _whiteListArray) public initializer {
        __Ownable_init_unchained();
        __setHelper();
        platformNFTAddress = _nftAddress;
        treasury = _treasury;
        addWhiteListAddress(_whiteListArray);
    }

    //Viewer
    function isWhiteList(address _address) public view returns(bool) {
        for(uint i = 0;i < whiteListNFT.length; i++) {
            if(whiteListNFT[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getIndex(address _address) public view returns(uint,bool) {
        for(uint i = 0;i < whiteListNFT.length; i++) {
            if(whiteListNFT[i] == _address) {
                return (i, true);
            }
        }
        return (0,false);
    }

    function getList() public view returns(address[] memory){
        return whiteListNFT;
    }



    //Setter//
    function addWhiteListAddress(address[] memory _whiteListArray) public onlyHelper{
        for(uint i = 0;i < _whiteListArray.length; i++) {
            require(isWhiteList(_whiteListArray[i]) == false, "Address already in white list");
            whiteListNFT.push(_whiteListArray[i]);
        }
    }


    function deleteWhiteListAddress(address[] memory _whiteListArray) public onlyHelper {
        for(uint i = 0;i < _whiteListArray.length; i++) {
            (uint index, bool ok) = getIndex(_whiteListArray[i]);
            if (ok == true) {
                deleteList(index);
            }
        }
    }

    function deleteList(uint index) internal {
        whiteListNFT[index] = whiteListNFT[whiteListNFT.length - 1];
        whiteListNFT.pop();
    }

    function setPlatformNFT(address _address) public onlyHelper{
        platformNFTAddress = _address;
    }
    function setTreasury(address _address)  public onlyHelper {
        treasury = _address;
    }

    //Function
    function rebirth(address _nftAddress, uint256[] calldata _tokenId) public  {
        require(isWhiteList(_nftAddress), "NFT address not in white list");
        for(uint i = 0; i < _tokenId.length; i++) {
            IERC721(_nftAddress).safeTransferFrom(msg.sender, treasury, _tokenId[i]);
        }
        IJomoDao(platformNFTAddress).batchMint(msg.sender, _tokenId.length);
        emit Rebirth(msg.sender,_nftAddress,_tokenId);
    }



}