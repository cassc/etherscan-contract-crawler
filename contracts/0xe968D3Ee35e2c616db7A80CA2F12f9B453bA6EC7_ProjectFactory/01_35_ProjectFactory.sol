// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "hardhat/console.sol";
import "./SaleFactory.sol";
import "./TokenFactory.sol";
import "../token/IToken.sol";
import "../sale/ISaleContract.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../interfaces/IRandomNumberProvider.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../../@galaxis/registries/contracts/Hook.sol";


interface OwnableContract {
    function owner() external view returns (address);
}


contract ProjectFactory is Ownable, BlackHolePrevention {
    using Strings  for uint256; 
    using Strings  for uint32; 
    using Strings  for uint8; 

    IRegistryConsumer               public TheRegistry;
    string              constant    public REGISTRY_KEY_RANDOM_CONTRACT  = "RANDOMV2_SSP";
    string              constant    public REGISTRY_KEY_PROJECT_FACTORY_CONTRACT  = "PROJECT_FACTORY";
    string              constant    public REGISTRY_KEY_COMMUNITY_LIST   = "COMMUNITY_LIST";
    string              constant    public REGISTRY_KEY_SSP_FACTORY_HOOK = "SSP_FACTORY_HOOK";
    bytes32             constant    public COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");

    TokenFactoryV1                  public TokenFactory;
    SaleFactoryV1                   public SaleFactory;


    uint256 public projectCount = 0;
    uint256 public projectIdOffset = 0;
    uint256 public chainid = 0;

    event NewProject(uint256 _projectCount);

    constructor(
        address TokenFactoryAddress,
        address SaleFactoryAddress
    ) {
        uint256 id;
        assembly {
            id := chainid()
        }
        chainid = id;

        if(chainid == 1 || chainid == 5 || chainid == 1337 || chainid == 31337) {
            TheRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
        } else {
            require(false, "ProjectFactory: invalid chainId");
        }

        TokenFactory = TokenFactoryV1(TokenFactoryAddress);
        SaleFactory = SaleFactoryV1(SaleFactoryAddress);
    }

    function LaunchProject(
        uint32 communityId,
        SaleConfiguration memory saleConfig,
        TokenConstructorConfig memory tokenConfig
    ) external  {

        // validate this contract is the current version to be used. else fail
        address PROJECT_FACTORY = TheRegistry.getRegistryAddress(REGISTRY_KEY_PROJECT_FACTORY_CONTRACT);
        require(PROJECT_FACTORY == address(this), "ProjectFactory: Not current project factory.");

        CommunityList COMMUNITY_LIST = CommunityList(TheRegistry.getRegistryAddress(REGISTRY_KEY_COMMUNITY_LIST));
        (, address crAddr, ) = COMMUNITY_LIST.communities(communityId);
        require(crAddr != address(0), "ProjectFactory: Invalid community ID");
        CommunityRegistry thisCommunityRegistry = CommunityRegistry(crAddr);
        require(thisCommunityRegistry.isUserCommunityAdmin(COMMUNITY_REGISTRY_ADMIN, msg.sender), "ProjectFactory: Community not owned by sender");
        
        // require(thisCommunityRegistry.community_admin() == msg.sender, "ProjectFactory: Not owned by sender");
            
        saleConfig.projectID = communityId;
        tokenConfig.projectID = communityId;

        // Launch new token contract
        address _newTokenAddress = TokenFactory.deploy(tokenConfig, msg.sender);

        // add the new token contract address into the sale
        saleConfig.token = _newTokenAddress;

        // Launch new sale contract
        address _newSaleAddress = SaleFactory.deploy(saleConfig, msg.sender);

        // Give sale contract TOKEN_CONTRACT_ACCESS_SALE role in Community Registry so it can call mint methods in token
        thisCommunityRegistry.grantRole(
            IToken(_newTokenAddress).TOKEN_CONTRACT_ACCESS_SALE(),
            _newSaleAddress
        );

        // give random number provider access to the token
        IRandomNumberProvider random = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT));
        random.setAuth(address(_newTokenAddress), true);

        // set community token counts 
        uint256 existingTokenCount = thisCommunityRegistry.getRegistryUINT("TOKEN_COUNT");
        thisCommunityRegistry.setRegistryUINT("TOKEN_COUNT", ++existingTokenCount);

        // set new community token address
        thisCommunityRegistry.setRegistryAddress(
            string(abi.encodePacked("TOKEN_", existingTokenCount.toString())),
            _newTokenAddress
        );

        // set community sale counts 
        uint256 existingSaleCount = thisCommunityRegistry.getRegistryUINT("SALE_COUNT");
        thisCommunityRegistry.setRegistryUINT("SALE_COUNT", ++existingSaleCount);

        // set new community sale address
        thisCommunityRegistry.setRegistryAddress(
            string(abi.encodePacked("SALE_", existingSaleCount.toString())),
            _newSaleAddress
        );

        // call finish hook
        // hook finishHook = hook( TheRegistry.getRegistryAddress(REGISTRY_KEY_SSP_FACTORY_HOOK) );
        // HookData memory data = HookData(
        //     communityId, 
        //     saleConfig,
        //     tokenConfig
        // );
        // finishHook.TJHooker(
        //     "SSP_FACTORY_HOOK_NEW_PROJECT", data
        // );


        emit NewProject(communityId);
    }

    struct HookData {
        uint32 communityId;
        SaleConfiguration saleConfig;
        TokenConstructorConfig tokenConfig;
    }


    struct ProjectDetails {
        address[] tokenContracts;
        address[] saleContracts;
        TokenInfo[] tokenInfo;
        SaleInfo[] saleInfo;
        uint256 chainid;
    }

    function getProjectDetails(uint32 communityId) public view returns (ProjectDetails memory) {

        CommunityList COMMUNITY_LIST = CommunityList(TheRegistry.getRegistryAddress(REGISTRY_KEY_COMMUNITY_LIST));
        (, address crAddr, ) = COMMUNITY_LIST.communities(communityId);
        require(crAddr != address(0), "ProjectFactory: Invalid community ID");
        CommunityRegistry thisCommunityRegistry = CommunityRegistry(crAddr);

        uint256 existingTokenCount = thisCommunityRegistry.getRegistryUINT("TOKEN_COUNT");
        uint256 existingSaleCount = thisCommunityRegistry.getRegistryUINT("SALE_COUNT");

        address[] memory _tokenAddresses = new address[](existingTokenCount);
        TokenInfo[] memory _tokenInfo = new TokenInfo[](existingTokenCount);
        for(uint8 i = 0; i < existingTokenCount; i++) {
            string memory key = string(abi.encodePacked("TOKEN_", (i+1).toString()));
            address thisAddress = thisCommunityRegistry.getRegistryAddress(key);
            if(thisAddress != address(0)) {
                _tokenAddresses[i] = thisAddress;
                _tokenInfo[i] = IToken(thisAddress).tellEverything();
            } 
        }

        address[] memory _saleAddresses = new address[](existingSaleCount);
        SaleInfo[] memory _saleInfo = new SaleInfo[](existingSaleCount);
        for(uint8 i = 0; i < existingSaleCount; i++) {

            string memory key = string(abi.encodePacked("SALE_", (i+1).toString()));
            address thisAddress = thisCommunityRegistry.getRegistryAddress(key);
            if(thisAddress != address(0)) {
                _saleAddresses[i] = thisAddress;
                _saleInfo[i] = ISaleContract(thisAddress).tellEverything();
            } 
        }

        return ProjectDetails(
            _tokenAddresses,
            _saleAddresses,
            _tokenInfo,
            _saleInfo,
            chainid
        );
    }

}