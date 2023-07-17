// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/***             
 *                                          ▓▓▓▄,
                                          ▓█╬▀██▓▄╖
                                         ╓██░░╠╠╬╬███▄,
                                        ▄██░░░░╚╠╠╠╠╬╬██▓µ
                                     ╓▓██╬░░░░░░╠╬╬╬╬╬╬╬╬██▄
                                ,▄▓███╬░▒▒▒▒▒▒▒▒▒╬╬╬╬╬╬╬╬╬╬██▓
                           ,▄▓███▓╬╠▒▒▒▒▒▒▒▒▒▒▒▒╠╬╬╬╬╬╬╬╬╬╬╬╬██▌
                        ╓▓██▓╬╬╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
                      ╓▓█▓╬╬▒╠╠╠╠╠╠╠╠╠╠╠╠╠▒╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
                     ]██╬╬╬▒╠╠╠╠╠╠╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣█▌
                     ╫█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
                     ╟█▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣██
                     ▄██╬╬╬╬╬▓▓▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▓▓▓╬╬╬╬╬╬▓██▓µ
                 ▄▓██▓▀╬╬▓█▀▀╙└└└╙╙▀██╬╬╬╬╬╬╬╬╬╬╬╬██▀▀╙└└└╙╙▀██▒╠╠╠╬╬██▄
              ,▓██╬╬▒▒▒▓█╙   ,╓╦µ,   └▀█╬╬╬╬╬╬╬╬██╙   ,╓╦µ,   └▀█▒▒╠╠╬╬██▄
             ╔██▒╬╬▒╠▒█▌      └╫▓▓▓ε   ╚█╬╬╬╬╬╬█▌      └╫▓▓▓ε   ╚█▒╠╠╠╬╬╣█▌
            ]██╬╬╬╬╬╠╟█    φ░░░╫▓▓▓▓    █▌╠╠╠╠╟█    φ░░░╫▓▓▓▓    █▌╠╠╬╬╬╬╟█▌
            ╫█▒╬╬╬╬╬╬╫█    ██▓██████⌐   ▓█╠╠╠╠╟█    ██▓██████⌐   ▓█╬╬╬╬╬╬╬██
            ╟█╬╬╬╬╬╬╬╬█▄   ╚█████▒ε    ]█▒╬╬╬╬╬█▄   ╚█████▒ε    ]█▒╬╬╬╬╬╬╣██
            ╙██╬╬╬╬╬╬╬╬█▄   ╙▀███▀"   ▄█▓╬╬╬╬╬╬╬█▄   ╙▀███▀"   ▄█▓╬╬╬╬╬╬╬▓█▌
             ▓█▓╬╬╬╬╬╬╬╬██▄Q       ╓▄██╬╬╬╬╬╬╬╬╬╬██▄Q       ╓▄██╬╬╬╬╬╬╬╬╣██▄
          ╓▓█╬╠╠╬╬╠╠╠╬╬╬╬╬╬╬████████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬████████╬╬╬╬╬╬╬╠╠╬╬╠╠╬██▓
        ╓▓█╬╬╬╠╠╠╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠╠╬██▌
       á██╬╠▒▒▒▒╠╠╠╠╠╠╬╬╬▓█████▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓██████╬╬╬╠╠╠╠╠╠▒▒▒▒╠╠╣█▌
      ]██╬╬╠╠╠╠╠╠╠╠╠╠╠╠▓█╬╬╠╠╬╬╬╬███████▓▓▓▓▓▓▓▓███████▀╬╬╬╠╠╬╬██▒╠╠╠╠╠╠╠╠╠╠╠╠╬╫█▌
      ╫█▒╬╬╬╠╠╠╠╠╠╠╠╠╠╟█▒╠╠╠╠╠╠╠╠╠╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠╠╠╠╠╠╠█▌╠╠╠╠╠╠╠╠╠╠╠╬╬╬██
      ╫█╬╬╬╬╬╬╬╠╠╠╠╠╠╠╬█▌╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╟█▒╠╠╠╠╠╠╠╠╬╬╬╬╬╣██
      ║██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██▓▄▒╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠▒▒▓██▒╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣█▌
       ▓█╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓███▓▄▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄▄▓████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
        ██▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬███████████████████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣██¬
         ╚██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██▀
           ▀██▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓██▀
             └▀███▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓███▀╙
                 └╙▀█████▓▓▓╬╬╬╬╬╬╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╣╬╬╬╬╬╬▓▓▓▓████▀▀└
                        └╙╙▀▀▀████████████████████████████▀▀▀▀╙╙                                                                                             
***/
interface IShitGPT {
    function transfer(address recipient, uint256 amount) external;

    function burn(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

interface ERC721 {
    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract ShitGPTClaimDrop {
    mapping(address => bool) public isERC721ContractValid;
    mapping(address => uint256) public claimableAmounts;
    mapping(address => mapping(uint256 => bool)) public claimedTokens;

    address public shitGPTContract;
    address public contractOwner;

    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "Only the contract owner can call this function."
        );
        _;
    }

    constructor(address _tokenAddress) {
        contractOwner = msg.sender;
        initializeERC721Contracts();
        shitGPTContract = _tokenAddress;
    }

    function initializeERC721Contracts() internal {
        // Add the ERC721 contracts to the mapping
        isERC721ContractValid[
            0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D
        ] = true; // Bored Ape Yacht Club
        isERC721ContractValid[
            0x60E4d786628Fea6478F785A6d7e704777c86a7c6
        ] = true; // Mutant Ape Yacht Club
        isERC721ContractValid[
            0xED5AF388653567Af2F388E6224dC7C4b3241C544
        ] = true; // Azuki
        isERC721ContractValid[
            0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB
        ] = true; // CryptoPunks
        isERC721ContractValid[
            0x5Af0D9827E0c53E4799BB226655A1de152A425a5
        ] = true; // Milady
        isERC721ContractValid[
            0xBd3531dA5CF5857e7CfAA92426877b022e612cf8
        ] = true; // Pudgy Penguins
        isERC721ContractValid[
            0xd774557b647330C91Bf44cfEAB205095f7E6c367
        ] = true; // Nakamigos
        isERC721ContractValid[
            0x8821BeE2ba0dF28761AffF119D66390D594CD280
        ] = true; // DeGods
        isERC721ContractValid[
            0x79FCDEF22feeD20eDDacbB2587640e45491b757f
        ] = true; // Mfer
        isERC721ContractValid[
            0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e
        ] = true; // Doodles
        isERC721ContractValid[
            0x23581767a106ae21c074b2276D25e5C3e136a68b
        ] = true; // Moonbirds
        isERC721ContractValid[
            0x49cF6f5d44E70224e2E23fDcdd2C053F30aDA28B
        ] = true; // CloneX
        isERC721ContractValid[
            0xEeca64ea9fCf99A22806Cd99b3d29cf6e8D54925
        ] = true; // Sproto Gremlins
        isERC721ContractValid[
            0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6
        ] = true; // CrypToadz by GREMPLIN
        isERC721ContractValid[
            0x8c6dEf540b83471664Edc6d5Cf75883986932674
        ] = true; // Goblintown
    }

    function activateClaim(
        address erc721Contract,
        uint256 claimAmount
    ) external onlyOwner {
        require(claimAmount > 0, "Claim amount must be greater than zero.");
        require(
            isERC721ContractValid[erc721Contract],
            "Invalid ERC721 contract."
        );
        claimableAmounts[erc721Contract] = claimAmount;
    }

    function claim(address erc721Contract, uint256[] memory tokenIds) external {
        require(tokenIds.length > 0, "No token IDs provided.");
        require(
            isERC721ContractValid[erc721Contract],
            "Invalid ERC721 contract."
        );

        ERC721 erc721 = ERC721(erc721Contract);

        uint256 totalClaimAmount;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            require(
                erc721.ownerOf(tokenId) == msg.sender,
                "You are not the owner of one or more token IDs."
            );
            require(
                !claimedTokens[erc721Contract][tokenId],
                "One or more token IDs have already been claimed."
            );

            claimedTokens[erc721Contract][tokenId] = true;
            totalClaimAmount += claimableAmounts[erc721Contract];
        }

        require(
            totalClaimAmount > 0,
            "Claim amount is not set for one or more token IDs."
        );

        IShitGPT token = IShitGPT(shitGPTContract);
        token.transfer(msg.sender, totalClaimAmount);
    }

    function burn() external onlyOwner {
        IShitGPT token = IShitGPT(shitGPTContract);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No ShitGPT tokens to burn.");

        token.burn(balance);
    }

    function addERC721Contract(address erc721Contract) external onlyOwner {
        require(
            erc721Contract != address(0),
            "Invalid ERC721 contract address."
        );

        ERC721 erc721 = ERC721(erc721Contract);
        require(
            erc721.supportsInterface(0x80ac58cd),
            "Invalid ERC721 contract."
        );

        isERC721ContractValid[erc721Contract] = true;
    }

    function getClaimable(
        address erc721Contract,
        uint256[] memory tokenIds
    ) external view returns (bool[] memory) {
        require(
            isERC721ContractValid[erc721Contract],
            "Invalid ERC721 contract."
        );

        bool[] memory claimStatus = new bool[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            claimStatus[i] =
                !claimedTokens[erc721Contract][tokenId] &&
                claimableAmounts[erc721Contract] > 0;
        }
        return claimStatus;
    }
}