// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.16;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

 
contract CrowdfundingContract is Initializable, ERC1155URIStorageUpgradeable, ERC1155BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable{
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
    mapping(bytes => bool) public signedIpfsHashesUsed;

    event Burn(address indexed _owner, uint256 indexed _tokenId);
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin can call this function");
        _;
    }

    function initialize(
            uint _totalSupply,
            uint256 _pricePerNft,
            address _tokenAddress,
            address _adminAddress,
            address _projectOwnerAddress,
            uint _commisionPercent
        ) public initializer {
            __ERC1155_init("");
            __ERC1155URIStorage_init();
            __ERC1155Burnable_init();
            __Ownable_init();
            _setBaseURI("https://pinata.dualmint.io/ipfs/");  
            totalSupply = _totalSupply;
            pricePerNft = _pricePerNft;
            tokenAddress = IERC20Upgradeable(_tokenAddress);
            adminAddress = _adminAddress;
            projectOwnerAddress = _projectOwnerAddress;
            commissionPercent = _commisionPercent;
            isActive = true;
    }

    function mint(uint _numberOfTokens, string[] memory _ipfsHashes, bytes[] memory _signedIpfsHashes ) public returns (uint256[] memory tokenIds){
        return mintInternal(_msgSender(),_numberOfTokens, _ipfsHashes, _signedIpfsHashes, pricePerNft);
    }
    
    function assistedMint(uint _numberOfTokens, address _ownerAddress, string[] memory _ipfsHashes, bytes[] memory _signedIpfsHashes) public payable returns (uint256[] memory tokenIds){
        return mintInternal(_ownerAddress, _numberOfTokens, _ipfsHashes, _signedIpfsHashes, pricePerNft);
    }

    function presaleMint(
        bytes32 _hash,
        bytes memory signature,
        uint256 _numberOfTokens,
        uint256 _customPricePerNft,
        address _ownerAddress,
        string[] memory _ipfsHashes,
        bytes[] memory _signedIpfsHashes
    ) external returns (uint256[] memory tokenIds)
    {   
        // require(isActive, "Cannot Mint");
        require(keccak256(abi.encodePacked(address(_ownerAddress),_customPricePerNft,_numberOfTokens,address(this)))==_hash,"Incorrect details passed");
        require(recoverSigner(_hash, signature) == projectOwnerAddress, "Address is not allowlisted");
        require(!signatureUsed[signature],"Signature is already used");
        signatureUsed[signature] = true;
        return mintInternal(_ownerAddress, _numberOfTokens, _ipfsHashes, _signedIpfsHashes, _customPricePerNft);
    }

    function mintInternal(address _to, uint _numberOfTokens, string[] memory _ipfsHashes, bytes[] memory _signedIpfsHashes, uint _atPrice) internal returns(uint256[] memory tokenIds) {
        require(_ipfsHashes.length == _numberOfTokens && _signedIpfsHashes.length == _numberOfTokens, "Ipfs length mismatch");
        require(isActive, "Cannot Mint");
        require(totalMinted + _numberOfTokens <= totalSupply, "Goal reached already");
        require(tokenAddress.allowance(_msgSender(), address(this))>=(_numberOfTokens*pricePerNft),"insufficient allowance");
        bool transferSuccessful = tokenAddress.transferFrom(_msgSender(),address(this),_numberOfTokens*_atPrice); // transfer of funds to marketplace contract
        require(transferSuccessful,"transfer of tokens unsuccessful"); //)
        commissions += (_numberOfTokens*_atPrice*commissionPercent)/100;
        projectBalance += ((100-commissionPercent)*_numberOfTokens*_atPrice)/100;
        if(_numberOfTokens==1){
            _mint(_to, ++totalMinted, 1, bytes(string(abi.encodePacked(_to," Minting ",_numberOfTokens," tokens"))));
            // require(!signedIpfsHashesUsed[_signedIpfsHashes[0]],"IPFS used already");
            // require(recoverSigner(keccak256(abi.encodePacked(_ipfsHashes[0])),_signedIpfsHashes[0])==adminAddress, "Incorrect IPFS Signature");//ASK BILL
            // _setURI(totalMinted+1, _ipfsHashes[0]);
            // signedIpfsHashesUsed[_signedIpfsHashes[0]] = true;
            verifyAndUseIpfsHash(totalMinted, _ipfsHashes[0], _signedIpfsHashes[0]);
            nftPriceArray[totalMinted] = _atPrice;
            //nftPriceArray[totalMinted+1] = _atPrice;
            //++totalMinted;
            uint256[] memory tokenIdsArray = new uint256[](1);
            tokenIdsArray[0] = totalMinted;
            return tokenIdsArray;

        } 
        else {
            uint256[] memory tokenIdsArray = new uint256[](_numberOfTokens);
            uint256[] memory amountsArray = new uint256[](_numberOfTokens);
            for (uint256 i=0; i<_numberOfTokens; i++){
                tokenIdsArray[i] = totalMinted + i + 1;
                amountsArray[i] = 1;
                nftPriceArray[ totalMinted + i + 1] = _atPrice;
                // require(!signedIpfsHashesUsed[_signedIpfsHashes[i]],"IPFS used already");
                // require(recoverSigner(keccak256(abi.encodePacked(_ipfsHashes[i])),bytes(_ipfsHashes[i]))==adminAddress, "Incorrect IPFS Signature");//ASK BILL
                // _setURI(totalMinted + i + 1, _ipfsHashes[i]);
                // signedIpfsHashesUsed[_signedIpfsHashes[i]] = true;
                verifyAndUseIpfsHash(totalMinted+i+1, _ipfsHashes[i], _signedIpfsHashes[i]);
            }
            _mintBatch(_to,tokenIdsArray, amountsArray, bytes(string(abi.encodePacked(_to," Minting ",_numberOfTokens," tokens"))));
            totalMinted+=_numberOfTokens;
            return tokenIdsArray;
        }
    }


    function _setURI(uint256 _tokenId, string memory _uri) internal override(ERC1155URIStorageUpgradeable) {
        ERC1155URIStorageUpgradeable._setURI(_tokenId, _uri);
    }

    function uri(uint256 _tokenId) public view override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) returns (string memory) {
        return ERC1155URIStorageUpgradeable.uri(_tokenId);
    }

    function verifyAndUseIpfsHash(uint _tokenId, string memory _ipfsHash, bytes memory _signature) internal {
        require(!signedIpfsHashesUsed[_signature],"IPFS used already");
        require(recoverSigner(keccak256(abi.encodePacked(_ipfsHash)),_signature)==adminAddress, "Incorrect IPFS Signature");
        _setURI(_tokenId, _ipfsHash);
        signedIpfsHashesUsed[_signature] = true;
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
        require(ERC1155Upgradeable.balanceOf(msg.sender,_tokenId)>0, "Zero balance");
        _burn(msg.sender,_tokenId,1);
        bool transferSuccessful = tokenAddress.transfer(msg.sender, nftPriceArray[_tokenId]);// needs to be edited
        require(transferSuccessful,"transfer of tokens unsuccessful");
        emit Burn(msg.sender, _tokenId); // add a log statement
    }

    function burnMultiple(uint256[] memory _tokenIds, uint256[] memory _amounts) public {
        require(!isActive, "Goal pending");
        _burnBatch(msg.sender, _tokenIds, _amounts);
        uint256 balance = 0;
        for (uint256 i = 0; i < _tokenIds.length; ++i){
            balance += nftPriceArray[_tokenIds[i]];
        }
        bool transferSuccessful = tokenAddress.transfer(msg.sender, balance);// needs to be edited
        require(transferSuccessful,"transfer of tokens unsuccessful");
    }
    
    // cash out function
    function withdrawProjectFunds() public {
        require(canWithdraw, "Project Unsuccessful");
        uint balance = projectBalance;
        projectBalance = 0;
        bool transferSuccessful = tokenAddress.transfer(projectOwnerAddress, balance);
        require(transferSuccessful,"transfer of tokens unsuccessful");
    }
    // commission function
    function withdrawCommissions() public {
        require(canWithdraw, "Project Unsuccessful");
        uint balance = commissions;
        commissions = 0;
        bool transferSuccessful = tokenAddress.transfer(adminAddress, balance);
        require(transferSuccessful,"transfer of tokens unsuccessful");
    }

    function addSupply(uint _supplyToAdd, uint _newPricePerNft) external onlyAdmin {
        require(isActive&&canWithdraw,"Project needs to be successful");
        require(totalMinted==totalSupply, "existing supply not exhausted");
        totalSupply += _supplyToAdd;
        pricePerNft = _newPricePerNft;
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
    

    // temp function only for testing
    function setTokenAddress(address _tokenAddress) external onlyAdmin {
        tokenAddress = IERC20Upgradeable(_tokenAddress);
    }
      // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

}