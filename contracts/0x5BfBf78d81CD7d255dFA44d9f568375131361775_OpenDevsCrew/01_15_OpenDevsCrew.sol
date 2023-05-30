// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./extensions/SmartCommunityWallet.sol";

contract OpenDevsCrew is SmartCommunityWallet {
  constructor()
  SmartCommunityWallet(
    /*
     * Once at least one token has been held for the following amount of time
     * the owner will automatically be considered a Diamond Hands Holder.
     *
     * In order to withdraw any funds from the Smart Community Wallet the
     * Diamond Hands Holder status is required.
     *
     * This status can also be verified by external contracts and Dapps.
     */
    90 days,

    /*
     * Diamond Hands Holders who are also owners of the following amount of
     * tokens (or more) are considered Whales. This allows them to perform extra
     * maintenance actions in extreme cases (see below).
     *
     * This status can also be verified by external contracts and Dapps.
     */
    20,

    /*
     * After an address has withdrawn funds from the Smart Community Wallet,
     * then any transfer of ODC tokens from the same address will be rejected
     * for the following amount of time.
     *
     * This is intended to mitigate misconduct such as withdrawing immediately
     * before accepting an offer. People can take this into consideration when
     * placing offers based on the funds associated with a token.
     *
     * If you are wondering why this works on an address basis and not on a
     * token basis, here are some considerations:
     *  - in most situations holders are probably gonna withdraw the funds for
     *    all of the their tokens at once in order to save gas
     *  - storing the required data to perform the same check on a token basis
     *    would be unreasonably expensive in terms of gas consumption
     */
    24 hours,

    /*
     * We don't want any funds to get stuck into this contract for any reasons,
     * but they are attached to the NFTs so only the owner of each token can
     * call the withdraw function.
     *
     * Setting an inactivity time frame makes it possible for Whales to withdraw
     * on behalf of inactive addresses in the following scenarios:
     * 1) a holder completely loses access to his wallet
     * 2) a token is transferred by mistake to any inactive address (e.g. a
     *    random one or the black hole)
     * 3) most human beings are exterminated by an army of AI-crafted NFTs and
     *    the last chance for survivors to fight for their lives is to use the
     *    funds in this contract (hope there is still a Whale out there...)
     */
    2 * 365 days,

    /*
     * Address of the WETH contract in order to support unwrapping.
     */
    address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),

    /*
     * Donation to the HashLips Lab as a tribute for the educational and open
     * source work done for the Web3 space. (Daniel only, in order to avoid
     * useless round trips).
     */
    2, // %
    _HASHLIPS, // Wallet

    /*
     * MEP's share of mint funds to help with community activities.
     */
    _MEP // Wallet (% is implicitly 98%)
  )
  NftToken(
    // ERC721 token name
    "OpenDevsCrew",

    // ERC721 token symbol
    "ODC",

    // Max supply
    1990,

    // Token price
    0.1 ether,

    // Max batch size (per mint TX)
    10,

    // Hidden metadata URI
    "https://cdn.opendevs.io/tokens/public/hidden/metadata.json",

    // Mint start timestamp (2022-10-28 17:00:00 UTC)
    1666976400
  ) {
    // Initial airdrops
    _mint(_LIARCO, 10);
    _mint(_FREAKS_PIX, 1);

    _mint(_LORVI, 5);
    _mint(_NIKI, 1);
    _mint(_MAPER, 2);
    _mint(_ZEKEL, 2);
    _mint(_LEO, 1);

    _mint(_HASHLIPS, 1);
    _mint(_D_R, 1);
    _mint(_LAINA, 1);

    _mint(_BADER, 1);
    _mint(_PRINCE, 1);

    _mint(_CYGAAR, 1);
    _mint(_VECTORIZED, 1);
  }

  /*
   * Hi, thank you for taking the time to review this code. It may seem strange
   * to read the following lines in a smart contract, but even if the ultimate
   * goal of this project is to create a decentralized brand for people who
   * share common passions and values, it all started with a group of people who
   * bumped into each other (physically or virtually) and somehow made this
   * happen, so I think it's fair to mention some of them here...
   *
   * I have no idea how weird it's gonna be to read this again in a few years,
   * but I wanna use the following comments to thank some of the people who have
   * had the most impact in bringing this idea to life.
   *
   * It has been an amazing journey so far, now let's challenge ourselves once
   * more and build something great together!
   *
   * Marco
   */
  address constant _LIARCO = address(0x4aF801f7DAC719A91f43b24ff0B68e2E422FE37b);

  /*
   * I can't thank Alessandro enough for his amazing work. He is one of the most
   * talented artists I know and I'm extremely grateful for the effort he put in
   * this collection.
   *
   * The tokens look awesome and they really reflect some of the values that are
   * core to this project... just to name a few:
   *   - happiness
   *   - friendliness
   *   - inclusion
   *   - attention to detail
   *   - and much more...
   *
   * ---
   * It has taken a long time to get here, but now it's finally time to give
   * these artworks a new home on the blockchain!
   */
  address constant _FREAKS_PIX = address(0x4372ec603b4E4ddEe322b6d00236854924D5Dc95);

  /*
   * A great friend and a fantastic business partner. Since the day we met,
   * Lorenzo has always made me feel part of his family and his company.
   *
   * ---
   * This is another chapter in our journey, we have challenging goals, but we
   * will work hard until we make it.
   */
  address constant _LORVI = address(0x19a7EF7bc82668358E985789c787bd7bd197dEF9);

  /*
   * Without a friend like Nicola, I wouldn't be here today writing these lines.
   *
   * ---
   * The crypto space was scary at first, but you have always been very
   * supportive and you motivated me to face my fears and combine my web2
   * experience with this exciting new stuff.
   *
   * Thank you.
   */
  address constant _NIKI = address(0x5d3BADdfB2F0Ad614bC073b269cC7c51F392108F);

  /*
   * A hard worker, a teammate and a great friend.
   *
   * ---
   * Despite my countless attempts to exhaust your patience, you always find a
   * way to make me evaluate any situations more rationally.
   *
   * I am very lucky to have you by my side.
   */
  address constant _MAPER = address(0x42E4a2c9710451aB3313398ac888738979476584);

  /*
   * I still remember his application and his presentation project for a job
   * position at our company. Nothing to add...
   *
   * ---
   * You have the right amount of positive unpredictability and enthusiasm in
   * order to make things spicy enough without hurting my OCD.
   *
   * Thank you for your patience, I'm extremely grateful to have you on board.
   */
  address constant _ZEKEL = address(0xE06A96E8046f63370942452dD5dFbC27035C4765);

  /*
   * Web3 is not all about code, art and DeFi. For this space to grow in a
   * sustainable way we have to bring in traditional businesses and show them
   * how these technologies can generate value in real life. Leonardo is helping
   * me finding good opportunities to achieve this result.
   *
   * ---
   * Thank you for your desire to learn new things and challenge yourself every
   * day.
   */
  address constant _LEO = address(0xB2aebb2615a337e1611215A241AeB3607FdFC086);

  /*
   * This guy allowed a huge amount of devs and artists to enter the Web3 space
   * without "exclusive access fees". This required large investments and
   * dedication to something that could have filled someone else's bags for
   * nothing in return. But he did it anyway.
   * It is certainly thanks to his hard work and support that I am here to
   * launch this project.
   *
   * ---
   * Thank you Daniel for the trust and support you show me every day. I can't
   * wait to see all the things we will build together!
   */
  address constant _HASHLIPS = address(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D);

  /*
   * I once called a complete stranger and told him about my idea to protect NFT
   * collections from snipers. Believe me when I say that there is a "me before
   * that call" and a "me after that call"... and those two are not the same
   * person.
   *
   * ---
   * Thank you D.R., that day I found at least two things:
   *   1) a huge opportunity
   *   2) a new good friend
   */
  address constant _D_R = address(0x97D348fe58478a1FA29de4726134815A57834880);

  /*
   * If you could put together the perfect mix of kindness and professionalism
   * in one person, then you would get a "Laina". But I'm pretty sure it is so
   * hard to achieve that she is probably a one-of-a-kind...
   *
   * ---
   * Thank you for your help and support. Your enthusiasm is a source of
   * motivation and great satisfaction.
   */
  address constant _LAINA = address(0x95A97387fa53052C38d66759167D07CB3861A1ec);

  /*
   * The way I got in touch with the DegenToonz community for the first time and
   * the stuff we did together after that day really prove that the web3 space
   * comes from another dimension. This is a once-in-a-lifetime opportunity and
   * we must not waste it.
   *
   * I can't wait to see what's next!
   *
   * ---
   * Thank you Bader and Prince for the trust and for being awesome partners.
   */
  address constant _PRINCE = address(0x85cbF39AfDB506CF9FA9A8Ea419c6De26C342cF0);
  address constant _BADER = address(0xD000874F10bFE76892C96aB0cF54861264455b1e);

  /*
   * Special thanks also go to the maintainers of the ERC721A project.
   * This collection is based on their codebase as most of the NFTs you can find
   * on any EVM-compatible chain.
   *
   * Disclaimer: this DOES NOT mean that this collection is officially endorsed
   *             or supported by any of them. We are simply using their open
   *             source library in our own project.
   *
   * ---
   * Thank you for your hard work. Your contribution to the NFT space is huge
   * and the educational value of your content on all platforms is priceless.
   */
  address constant _CYGAAR = address(0x6dacb7352B4eC1e2B979a05E3cF1F126AD641110);
  address constant _VECTORIZED = address(0x1F5D295778796a8b9f29600A585Ab73D452AcB1c);

  /*
   * The company MEP Srl is sponsoring my work since day one and it's providing
   * support with the launch of this project.
   *
   * ---
   * I wanna thank everyone for this great opportunity.
   */
  address constant _MEP = address(0x999Ee7a6734d06128F398741B604645A5e7C28E2);
}