// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/*
 ___                                ___                                                                                                 
(   )                              (   )                                                                                                
 | |    .--.    ___  ___    .--.    | |   ___  ___     ___ .-.      .---.    .--.      .--.      .--.     .--.    ___ .-.       .--.    
 | |   /    \  (   )(   )  /    \   | |  (   )(   )   (   )   \    / .-, \  /    \    /    \    /    \   /    \  (   )   \    /  _  \   
 | |  |  .-. ;  | |  | |  |  .-. ;  | |   | |  | |     | ' .-. ;  (__) ; | |  .-. ;  |  .-. ;  |  .-. ; |  .-. ;  |  .-. .   . .' `. ;  
 | |  | |  | |  | |  | |  |  | | |  | |   | |  | |     |  / (___)   .'`  | |  |(___) |  |(___) | |  | | | |  | |  | |  | |   | '   | |  
 | |  | |  | |  | |  | |  |  |/  |  | |   | '  | |     | |         / .'| | |  |      |  |      | |  | | | |  | |  | |  | |   _\_`.(___) 
 | |  | |  | |  | |  | |  |  ' _.'  | |   '  `-' |     | |        | /  | | |  | ___  |  | ___  | |  | | | |  | |  | |  | |  (   ). '.   
 | |  | '  | |  ' '  ; '  |  .'.-.  | |    `.__. |     | |        ; |  ; | |  '(   ) |  '(   ) | '  | | | '  | |  | |  | |   | |  `\ |  
 | |  '  `-' /   \ `' /   '  `-' /  | |    ___ | |     | |        ' `-'  | '  `-' |  '  `-' |  '  `-' / '  `-' /  | |  | |   ; '._,' '  
(___)  `.__.'     '_.'     `.__.'  (___)  (   )' |    (___)       `.__.'_.  `.__,'    `.__,'    `.__.'   `.__.'  (___)(___)   '.___.'   
                                           ; `-' '                                                                                      
                                            .__.'                                                                                       
*/

import "./ERC721Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";


error OnlyOnePerWallet(); 

contract LovelyRaccoonsGenesisU is Initializable, UUPSUpgradeable, ERC721Upgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable {

    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    using Strings for uint256;

    string private _baseTokenURI;
    address public communityWallet;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function initialize(address _communityWallet, string memory baseTokenURI_) initializer public {
        __ERC721_init("Lovely Raccoons Genesis", "GRACCS");
        __Ownable_init();
        __UUPSUpgradeable_init();
        __DefaultOperatorFilterer_init();
        communityWallet = _communityWallet;
        _baseTokenURI = baseTokenURI_;
        _mint(communityWallet, 100);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /*///////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseURI(),  _tokenId.toString())) : '';
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setCommunityWallet (address _communityWallet) external onlyOwner {
        communityWallet = _communityWallet;
    }

    /*///////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/


    function _beforeTokenTransfers(address, address to, uint256) internal view override {
        if (to != communityWallet && balanceOf(to) > 0) revert OnlyOnePerWallet();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /*///////////////////////////////////////////////////////////////
                    OPENSEA ENFORCING ROYALTIES
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from)  {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from)  {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) 
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}