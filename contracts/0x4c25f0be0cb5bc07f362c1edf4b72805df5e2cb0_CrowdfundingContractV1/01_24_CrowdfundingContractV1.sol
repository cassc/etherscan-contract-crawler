// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.16;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
 
//contract CrowdfundingContract is Initializable, OwnableUpgradeable, UUPSUpgradeable, ERC1155Upgradeable{
contract CrowdfundingContractV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable, ERC1155Upgradeable{
    string private baseURI;
    uint public totalSupply;
    uint public totalMinted;
    uint256 public pricePerNft;
    IERC20Upgradeable public tokenAddress;
    address public adminAddress;
    address public projectOwnerAddress;
    uint public projectBalance;
    uint public commissions;
    uint private commissionPercent;
    bool public canWithdraw;
    bool public isActive;
    mapping(uint256 => uint256) public nftPriceArray;
    mapping(bytes => bool) public signatureUsed; // The signature tracker for presale

    event Burn(address indexed _owner, uint256 indexed _tokenId);
    event BurnBatch(address indexed owner, uint256[] _tokenIds );
    event Mint(address indexed _owner, uint256[] indexed _tokenIds);
    event URI(string uri);
    modifier onlyAdmin() {
        require(_msgSender() == adminAddress, "Only admin can call this function");
        _;
    }

    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize(
            uint _totalSupply,
            uint256 _pricePerNft,
            address _tokenAddress,
            address _adminAddress,
            address _projectOwnerAddress,
            uint _commisionPercent,
            string memory _baseURI
        ) public initializer {
            __ERC1155_init(_baseURI);
            __Ownable_init(); 
            totalSupply = _totalSupply;
            pricePerNft = _pricePerNft;
            tokenAddress = IERC20Upgradeable(_tokenAddress);
            adminAddress = _adminAddress;
            projectOwnerAddress = _projectOwnerAddress;
            commissionPercent = _commisionPercent;
            isActive = true;
            baseURI = _baseURI;
            emit URI(baseURI);
    }

    function mint( uint _numberOfTokens ) public {
        mintInternal(_msgSender(), _numberOfTokens, pricePerNft);
    }
    
    function assistedMint(uint _numberOfTokens, address _ownerAddress) public payable {
        mintInternal(_ownerAddress, _numberOfTokens, pricePerNft);
    }

    function presaleMint(
        bytes32 _hash,
        bytes memory signature,
        uint256 _numberOfTokens,
        uint256 _customPricePerNft,
        address _ownerAddress
    ) external 
    {   
        require(keccak256(abi.encodePacked(address(_ownerAddress),_customPricePerNft,_numberOfTokens,address(this)))==_hash,"Incorrect details passed");
        require(recoverSigner(_hash, signature) == projectOwnerAddress, "Address is not allowlisted");
        require(!signatureUsed[signature],"Signature is already used");
        signatureUsed[signature] = true;
        mintInternal(_ownerAddress, _numberOfTokens, _customPricePerNft);
    }

    function mintInternal(address _to, uint _numberOfTokens, uint _atPrice) internal {
        require(isActive, "Cannot Mint");
        require(totalMinted + _numberOfTokens <= totalSupply, "Goal reached already");
        if(_atPrice>0){
            require(tokenAddress.allowance(_msgSender(), address(this))>=(_numberOfTokens*_atPrice),"insufficient allowance");
            IERC20Upgradeable(tokenAddress).safeTransferFrom(_msgSender(), address(this), _numberOfTokens*_atPrice);
            commissions += (_numberOfTokens*_atPrice*commissionPercent)/100;
            projectBalance += ((100-commissionPercent)*_numberOfTokens*_atPrice)/100;
        }
        if(_numberOfTokens==1){
            _mint(_to, ++totalMinted, 1, bytes(string(abi.encodePacked(_to," Minting ",_numberOfTokens," tokens"))));
            nftPriceArray[totalMinted] = _atPrice;
            uint256[] memory tokenIdsArray = new uint256[](1);
            tokenIdsArray[0] = totalMinted;
            emit Mint(_to, tokenIdsArray);
        } 
        else {
            uint256[] memory tokenIdsArray = new uint256[](_numberOfTokens);
            uint256[] memory amountsArray = new uint256[](_numberOfTokens);
            for (uint256 i=0; i<_numberOfTokens; i++){
                tokenIdsArray[i] = totalMinted + i + 1;
                amountsArray[i] = 1;
                nftPriceArray[ totalMinted + i + 1] = _atPrice;
            }
            _mintBatch(_to,tokenIdsArray, amountsArray, bytes(string(abi.encodePacked(_to," Minting ",_numberOfTokens," tokens"))));
            totalMinted+=_numberOfTokens;
            emit Mint(_to, tokenIdsArray);
        }
    }

    function uri(uint256 _tokenId) public view override(ERC1155Upgradeable) returns (string memory){
        return string(abi.encodePacked(baseURI,Strings.toString(_tokenId)));
    }

    function emergencyUpdateBaseURI(string memory _baseURI) public onlyAdmin {
        baseURI = _baseURI;
        emit URI(baseURI);
    }

    function projectSuccessful() public onlyAdmin {
        require(isActive, "Project already scrapped");
        canWithdraw = true;
    }

    function projectUnsuccessful() public onlyAdmin {
        require(isActive, "Project already scrapped");
        isActive = false;
        //canWithdraw false by default
    }

    function burnNFT(uint256 _tokenId) public {
        require(!isActive, "Goal pending");
        require(ERC1155Upgradeable.balanceOf(_msgSender(),_tokenId)>0, "Zero balance");
        _burn(_msgSender(),_tokenId,1);
        IERC20Upgradeable(tokenAddress).safeTransfer(_msgSender(), nftPriceArray[_tokenId]);
        emit Burn(_msgSender(), _tokenId); // add a log statement
    }

    function burnMultiple(uint256[] memory _tokenIds, uint256[] memory _amounts) public {
        require(!isActive, "Goal pending");
        _burnBatch(_msgSender(), _tokenIds, _amounts);
        uint256 balance = 0;
        for (uint256 i = 0; i < _tokenIds.length; ++i){
            balance += nftPriceArray[_tokenIds[i]];
        }
        IERC20Upgradeable(tokenAddress).safeTransfer(_msgSender(), balance);
        emit BurnBatch(_msgSender(), _tokenIds);
    }
    
    function withdrawProjectFunds() public {
        require(canWithdraw, "Project Unsuccessful");
        uint balance = projectBalance;
        projectBalance = 0;
        IERC20Upgradeable(tokenAddress).safeTransfer(projectOwnerAddress, balance);
    }
    
    function withdrawCommissions() public {
        require(canWithdraw, "Project Unsuccessful");
        uint balance = commissions;
        commissions = 0;
        IERC20Upgradeable(tokenAddress).safeTransfer(adminAddress, balance);
    }

    function addSupply(uint _supplyToAdd, uint _newPricePerNft, string memory _baseURI) external onlyAdmin {
        require(isActive&&canWithdraw,"Project needs to be successful");
        require(totalMinted==totalSupply, "existing supply not exhausted");
        totalSupply += _supplyToAdd;
        pricePerNft = _newPricePerNft;
        baseURI = _baseURI;
        emit URI(baseURI);
    }

    function changeProjectOwner(address _newProjectOwnerAddress) external onlyAdmin{
        require(isActive&&(!canWithdraw),"cannot change project owner now");
        projectOwnerAddress  = _newProjectOwnerAddress;
    }

    function projectStatus() external view returns (bool, bool, address, address, address, uint, uint, uint, uint, uint, uint) {
        return (isActive, canWithdraw, projectOwnerAddress, adminAddress, address(tokenAddress), totalMinted, totalSupply, pricePerNft, projectBalance, commissions, commissionPercent);
    }

    function recoverSigner(bytes32 _hash, bytes memory signature) internal pure returns (address) {
            bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
            return ECDSAUpgradeable.recover(messageDigest, signature);
    }
    
      // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}