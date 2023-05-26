// SPDX-License-Identifier: MIT
/*                                                                                                                                                                                                                                            
                                                                                                                                               bbbbbbbb                                                                                      
PPPPPPPPPPPPPPPPP                                                       hhhhhhh                          CCCCCCCCCCCCClllllll                  b::::::b                 PPPPPPPPPPPPPPPPP                                                    
P::::::::::::::::P                                                      h:::::h                       CCC::::::::::::Cl:::::l                  b::::::b                 P::::::::::::::::P                                                   
P::::::PPPPPP:::::P                                                     h:::::h                     CC:::::::::::::::Cl:::::l                  b::::::b                 P::::::PPPPPP:::::P                                                  
PP:::::P     P:::::P                                                    h:::::h                    C:::::CCCCCCCC::::Cl:::::l                   b:::::b                 PP:::::P     P:::::P                                                 
  P::::P     P:::::P  eeeeeeeeeeee    aaaaaaaaaaaaa      cccccccccccccccch::::h hhhhh             C:::::C       CCCCCC l::::l uuuuuu    uuuuuu  b:::::bbbbbbbbb           P::::P     P:::::Paaaaaaaaaaaaa      ssssssssss       ssssssssss   
  P::::P     P:::::Pee::::::::::::ee  a::::::::::::a   cc:::::::::::::::ch::::hh:::::hhh         C:::::C               l::::l u::::u    u::::u  b::::::::::::::bb         P::::P     P:::::Pa::::::::::::a   ss::::::::::s    ss::::::::::s  
  P::::PPPPPP:::::Pe::::::eeeee:::::eeaaaaaaaaa:::::a c:::::::::::::::::ch::::::::::::::hh       C:::::C               l::::l u::::u    u::::u  b::::::::::::::::b        P::::PPPPPP:::::P aaaaaaaaa:::::ass:::::::::::::s ss:::::::::::::s 
  P:::::::::::::PPe::::::e     e:::::e         a::::ac:::::::cccccc:::::ch:::::::hhh::::::h      C:::::C               l::::l u::::u    u::::u  b:::::bbbbb:::::::b       P:::::::::::::PP           a::::as::::::ssss:::::ss::::::ssss:::::s
  P::::PPPPPPPPP  e:::::::eeeee::::::e  aaaaaaa:::::ac::::::c     ccccccch::::::h   h::::::h     C:::::C               l::::l u::::u    u::::u  b:::::b    b::::::b       P::::PPPPPPPPP      aaaaaaa:::::a s:::::s  ssssss  s:::::s  ssssss 
  P::::P          e:::::::::::::::::e aa::::::::::::ac:::::c             h:::::h     h:::::h     C:::::C               l::::l u::::u    u::::u  b:::::b     b:::::b       P::::P            aa::::::::::::a   s::::::s         s::::::s      
  P::::P          e::::::eeeeeeeeeee a::::aaaa::::::ac:::::c             h:::::h     h:::::h     C:::::C               l::::l u::::u    u::::u  b:::::b     b:::::b       P::::P           a::::aaaa::::::a      s::::::s         s::::::s   
  P::::P          e:::::::e         a::::a    a:::::ac::::::c     ccccccch:::::h     h:::::h      C:::::C       CCCCCC l::::l u:::::uuuu:::::u  b:::::b     b:::::b       P::::P          a::::a    a:::::assssss   s:::::s ssssss   s:::::s 
PP::::::PP        e::::::::e        a::::a    a:::::ac:::::::cccccc:::::ch:::::h     h:::::h       C:::::CCCCCCCC::::Cl::::::lu:::::::::::::::uub:::::bbbbbb::::::b     PP::::::PP        a::::a    a:::::as:::::ssss::::::ss:::::ssss::::::s
P::::::::P         e::::::::eeeeeeeea:::::aaaa::::::a c:::::::::::::::::ch:::::h     h:::::h        CC:::::::::::::::Cl::::::l u:::::::::::::::ub::::::::::::::::b      P::::::::P        a:::::aaaa::::::as::::::::::::::s s::::::::::::::s 
P::::::::P          ee:::::::::::::e a::::::::::aa:::a cc:::::::::::::::ch:::::h     h:::::h          CCC::::::::::::Cl::::::l  uu::::::::uu:::ub:::::::::::::::b       P::::::::P         a::::::::::aa:::as:::::::::::ss   s:::::::::::ss  
PPPPPPPPPP            eeeeeeeeeeeeee  aaaaaaaaaa  aaaa   cccccccccccccccchhhhhhh     hhhhhhh             CCCCCCCCCCCCCllllllll    uuuuuuuu  uuuubbbbbbbbbbbbbbbb        PPPPPPPPPP          aaaaaaaaaa  aaaa sssssssssss      sssssssssss    
*/

pragma solidity ^0.8.15;

import "@turtlecasedao/erc721g/contracts/ERC721G.sol";

contract PeachClubPass is ERC721G {
    uint256 private teamPC;
    bool    private isPublicActive;
    string  private baseURI = "ipfs://QmXd5672YxdDEpdX5LXPw7cZUQjrVuSsTHmDY9iC8ycwEC/";
    uint256 private amount;
    uint256 private price;
    mapping(address => uint256) private mintedPublicAddress;
    mapping(address => uint256) private addressBlockBought;


    
    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender, "CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isPublicActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        } 
        _;
    }

    modifier beforeAndAfter(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= amount, "EXCEEDS_MAX_SUPPLY");
        // uint256 before_ = totalSupply();
        _;
        // uint256 after_ = totalSupply();
        addressBlockBought[msg.sender] = block.timestamp;
        // for (uint i = before_; i < after_; ++i) {
        //     _tokenGuardService[i] = true;
        // }
    }

    constructor() ERC721G("Peach Club Pass", "pcp") {
        teamPC = 50;
        amount = 500;
        price = 1;
    }

    function mintPublic(
        uint256 numberOfTokens
    ) external payable isSecured(1) beforeAndAfter(numberOfTokens) {
        require(msg.value >= (0.01 ether) * numberOfTokens * price, "INSUFFICIENT_PAYMENT");
        require(mintedPublicAddress[msg.sender] + numberOfTokens <= 10, "ALREADY_MINTED_MAX");

        mintedPublicAddress[msg.sender] += numberOfTokens;
        _mint(msg.sender, numberOfTokens);
    }

    function mintPCPForTeam(uint256 numberOfTokens) external onlyOwner {
        require(teamPC > 0, "NFTS_FOR_THE_TEAM_HAS_BEEN_MINTED");
        require(numberOfTokens <= teamPC, "EXCEEDS_MAX_MINT_FOR_TEAM");

        teamPC -= numberOfTokens;
        _mint(msg.sender, numberOfTokens);
    }

    function togglePublicMintActive() external onlyOwner {
        isPublicActive = !isPublicActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setAmount(uint256 newAmount) external onlyOwner {
        amount = newAmount;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }

}