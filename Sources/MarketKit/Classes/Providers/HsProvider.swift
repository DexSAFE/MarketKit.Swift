import Foundation
import RxSwift
import HsToolKit
import Alamofire
import ObjectMapper

class HsProvider {
    private let baseUrl: String
    private let networkManager: NetworkManager
    private let headers: HTTPHeaders?

    init(baseUrl: String, networkManager: NetworkManager, apiKey: String?) {
        self.baseUrl = baseUrl
        self.networkManager = networkManager

        headers = apiKey.flatMap { HTTPHeaders([HTTPHeader(name: "apikey", value: $0)]) }
    }

}

extension HsProvider {

    func marketOverviewSingle(currencyCode: String) -> Single<MarketOverviewResponse> {
        let parameters: Parameters = [
            "simplified": true,
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/markets/overview", method: .get, parameters: parameters, headers: headers)
    }

    func topMoversRawSingle(currencyCode: String) -> Single<TopMoversRaw> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/coins/top-movers", method: .get, parameters: parameters, headers: headers)
    }

}

extension HsProvider {

    // Status

    func statusSingle() -> Single<HsStatus> {
        networkManager.single(url: "\(baseUrl)/v1/status/updates", method: .get, headers: headers)
    }

    // Coins

    func allCoinsSingle() -> Single<[Coin]> {
        networkManager.single(url: "\(baseUrl)/v1/coins/list", method: .get, headers: headers)
    }

    func allBlockchainRecordsSingle() -> Single<[BlockchainRecord]> {
        networkManager.single(url: "\(baseUrl)/v1/blockchains/list", method: .get, headers: headers)
    }

    func allTokenRecordsSingle() -> Single<[TokenRecord]> {
        networkManager.single(url: "\(baseUrl)/v1/tokens/list", method: .get, headers: headers)
    }

    // Market Infos

    func marketInfosSingle(top: Int, currencyCode: String, defi: Bool) -> Single<[MarketInfoRaw]> {
        var parameters: Parameters = [
            "limit": top,
            "fields": "price,price_change_24h,market_cap,market_cap_rank,total_volume",
            "currency": currencyCode.lowercased(),
            "order_by_rank": "true",
        ]

        if defi {
            parameters["defi"] = "true"
        }

        return networkManager.single(url: "\(baseUrl)/v1/coins", method: .get, parameters: parameters, headers: headers)
    }

    func advancedMarketInfosSingle(top: Int, currencyCode: String) -> Single<[MarketInfoRaw]> {
        let parameters: Parameters = [
            "limit": top,
            "fields": "price,market_cap,market_cap_rank,total_volume,price_change_24h,price_change_7d,price_change_14d,price_change_30d,price_change_200d,price_change_1y,ath_percentage,atl_percentage",
            "currency": currencyCode.lowercased(),
            "order_by_rank": "true",
        ]

        return networkManager.single(url: "\(baseUrl)/v1/coins", method: .get, parameters: parameters, headers: headers)
    }

    func marketInfosSingle(coinUids: [String], currencyCode: String) -> Single<[MarketInfoRaw]> {
        let parameters: Parameters = [
            "uids": coinUids.joined(separator: ","),
            "fields": "price,price_change_24h,market_cap,market_cap_rank,total_volume",
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/coins", method: .get, parameters: parameters, headers: headers)
    }

    func marketInfosSingle(categoryUid: String, currencyCode: String) -> Single<[MarketInfoRaw]> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/categories/\(categoryUid)/coins", method: .get, parameters: parameters, headers: headers)
    }

    func marketInfoOverviewSingle(coinUid: String, currencyCode: String, languageCode: String) -> Single<MarketInfoOverviewResponse> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased(),
            "language": languageCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/coins/\(coinUid)", method: .get, parameters: parameters, headers: headers)
    }

    func marketInfoDetailsSingle(coinUid: String, currencyCode: String) -> Single<MarketInfoDetails> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/coins/\(coinUid)/details", method: .get, parameters: parameters, headers: headers)
                .map { (response: MarketInfoDetailsResponse) -> MarketInfoDetails in
                    response.marketInfoDetails()
                }
    }

    func marketInfoTvlSingle(coinUid: String, currencyCode: String, timePeriod: HsTimePeriod) -> Single<[ChartPoint]> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased(),
            "interval": timePeriod.rawValue
        ]

        return networkManager.single(url: "\(baseUrl)/v1/defi-protocols/\(coinUid)/tvls", method: .get, parameters: parameters, headers: headers)
                .map { (response: [MarketInfoTvlRaw]) -> [ChartPoint] in
                    response.compactMap { $0.marketInfoTvl }
                }
    }

    func marketInfoGlobalTvlSingle(platform: String, currencyCode: String, timePeriod: HsTimePeriod) -> Single<[ChartPoint]> {
        var parameters: Parameters = [
            "currency": currencyCode.lowercased(),
            "interval": timePeriod.rawValue
        ]

        if !platform.isEmpty {
            parameters["chain"] = platform
        }

        return networkManager.single(url: "\(baseUrl)/v1/global-markets/tvls", method: .get, parameters: parameters, headers: headers)
                .map { (response: [MarketInfoTvlRaw]) -> [ChartPoint] in
                    response.compactMap { $0.marketInfoTvl }
                }
    }

    func defiCoinsSingle(currencyCode: String) -> Single<[DefiCoinRaw]> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/defi-protocols", method: .get, parameters: parameters, headers: headers)
    }

    // Coin Categories

    func coinCategoriesSingle(currencyCode: String? = nil) -> Single<[CoinCategory]> {
        var parameters: Parameters = [:]
        if let currencyCode = currencyCode {
            parameters["currency"] = currencyCode.lowercased()
        }
        return networkManager.single(url: "\(baseUrl)/v1/categories", method: .get, parameters: parameters, headers: headers)
    }

    func coinCategoryMarketCapChartSingle(category: String, currencyCode: String?, timePeriod: HsTimePeriod) -> Single<[CategoryMarketPoint]> {
        var parameters: Parameters = [:]
        if let currencyCode = currencyCode {
            parameters["currency"] = currencyCode.lowercased()
        }
        parameters["interval"] = timePeriod.rawValue

        return networkManager.single(url: "\(baseUrl)/v1/categories/\(category)/market_cap", method: .get, parameters: parameters, headers: headers)
    }


    // Coin Prices

    func coinPricesSingle(coinUids: [String], currencyCode: String) -> Single<[CoinPrice]> {
        let parameters: Parameters = [
            "uids": coinUids.joined(separator: ","),
            "currency": currencyCode.lowercased(),
            "fields": "price,price_change_24h,last_updated"
        ]

        let request = networkManager.session.request("\(baseUrl)/v1/coins", method: .get, parameters: parameters, headers: headers)

        return networkManager
                .single(request: request, mapper: CoinPriceMapper())
                .map { (coinPriceResponses: [CoinPriceResponse]) -> [CoinPrice] in
                    coinPriceResponses.map { coinPriceResponse in
                        coinPriceResponse.coinPrice(currencyCode: currencyCode)
                    }
                }
    }

    func historicalCoinPriceSingle(coinUid: String, currencyCode: String, timestamp: TimeInterval) -> Single<HistoricalCoinPriceResponse> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased(),
            "timestamp": Int(timestamp)
        ]

        return networkManager.single(url: "\(baseUrl)/v1/coins/\(coinUid)/price_history", method: .get, parameters: parameters, headers: headers)
    }

    func coinPriceChartStart(coinUid: String) -> Single<CoinPriceStart> {
        networkManager.single(url: "\(baseUrl)/v1/coins/\(coinUid)/price_chart_start", method: .get, headers: headers)
    }

    func coinPriceChartSingle(coinUid: String, currencyCode: String, periodType: HsPeriodType) -> Single<[ChartCoinPriceResponse]> {
        var parameters: Parameters = [
            "currency": currencyCode.lowercased()
        ]

        switch periodType {
        case .byPeriod(let timePeriod):
            parameters["from_timestamp"] = Int(Date().timeIntervalSince1970 - timePeriod.range)
            parameters["interval"] = HsChartHelper.pointInterval(timePeriod).rawValue
        case .byStartTime(let startTime):
            parameters["interval"] = HsChartHelper.intervalForAll(genesisTime: startTime).rawValue
        }

        return networkManager.single(url: "\(baseUrl)/v1/coins/\(coinUid)/price_chart", method: .get, parameters: parameters, headers: headers)
    }

    // Holders

    func tokenHoldersSingle(coinUid: String, blockchainUid: String) -> Single<TokenHolders> {
        let parameters: Parameters = [
            "blockchain_uid": blockchainUid
        ]

        return networkManager.single(url: "\(baseUrl)/v1/analytics/\(coinUid)/holders", method: .get, parameters: parameters, headers: headers)
    }

    // Funds

    func coinInvestmentsSingle(coinUid: String) -> Single<[CoinInvestment]> {
        let parameters: Parameters = [
            "coin_uid": coinUid
        ]

        return networkManager.single(url: "\(baseUrl)/v1/funds/investments", method: .get, parameters: parameters, headers: headers)
    }

    func coinTreasuriesSingle(coinUid: String, currencyCode: String) -> Single<[CoinTreasury]> {
        let parameters: Parameters = [
            "coin_uid": coinUid,
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/funds/treasuries", method: .get, parameters: parameters, headers: headers)
    }

    func coinReportsSingle(coinUid: String) -> Single<[CoinReport]> {
        let parameters: Parameters = [
            "coin_uid": coinUid
        ]

        return networkManager.single(url: "\(baseUrl)/v1/reports", method: .get, parameters: parameters, headers: headers)
    }

    func twitterUsername(coinUid: String) -> Single<String?> {
        networkManager
                .single(url: "\(baseUrl)/v1/coins/\(coinUid)/twitter", method: .get, headers: headers)
                .map { (response: TwitterUsernameResponse) -> String? in
                    response.username
                }
    }

    func globalMarketPointsSingle(currencyCode: String, timePeriod: HsTimePeriod) -> Single<[GlobalMarketPoint]> {
        let parameters: Parameters = [
            "interval": timePeriod.rawValue,
            "currency": currencyCode
        ]

        return networkManager.single(url: "\(baseUrl)/v1/global-markets", method: .get, parameters: parameters, headers: headers)
    }

    //Top Platfroms

    func topPlatformsSingle(currencyCode: String) -> Single<[TopPlatformResponse]> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/top-platforms", method: .get, parameters: parameters)
    }

    func topPlatformCoinsListSingle(blockchain: String, currencyCode: String) -> Single<[MarketInfoRaw]> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/top-platforms/\(blockchain)/list", method: .get, parameters: parameters)
    }

    func topPlatformMarketCapChartSingle(platform: String, currencyCode: String?, timePeriod: HsTimePeriod) -> Single<[CategoryMarketPoint]> {
        var parameters: Parameters = [:]
        if let currencyCode = currencyCode {
            parameters["currency"] = currencyCode.lowercased()
        }
        parameters["interval"] = timePeriod.rawValue

        return networkManager.single(url: "\(baseUrl)/v1/top-platforms/\(platform)/chart", method: .get, parameters: parameters, headers: headers)
    }

    //Pro Charts

    private func proHeaders(sessionKey: String?) -> HTTPHeaders? {
        guard let sessionKey = sessionKey else {
            return headers
        }
        var proHeaders = HTTPHeaders()

        headers?.forEach { proHeaders.add($0) }
        proHeaders.add(.authorization(bearerToken: sessionKey))

        return proHeaders
    }

    func proDataSingle<T: ImmutableMappable>(path: String, coinUid: String, currencyCode: String, timePeriod: HsTimePeriod) -> Single<T> {
        let parameters: Parameters = [
            "coin_uid": coinUid,
            "currency": currencyCode.lowercased(),
            "interval": timePeriod.rawValue
        ]

        return networkManager.single(url: "\(baseUrl)/v1/\(path)", method: .get, parameters: parameters, headers: headers)
    }

    func proDataSingle<T: ImmutableMappable>(path: String, coinUid: String, timePeriod: HsTimePeriod) -> Single<T> {
        let parameters: Parameters = [
            "coin_uid": coinUid,
            "interval": timePeriod.rawValue
        ]

        return networkManager.single(url: "\(baseUrl)/v1/\(path)", method: .get, parameters: parameters, headers: headers)
    }

    func rankDataSingle<T: ImmutableMappable>(type: String, currencyCode: String? = nil) -> Single<[T]> {
        var parameters: Parameters = [
            "type": type
        ]

        if let currencyCode {
            parameters["currency"] = currencyCode.lowercased()
        }

        return networkManager.single(url: "\(baseUrl)/v1/analytics/ranks", method: .get, parameters: parameters, headers: headers)
    }

    func analyticsSingle(coinUid: String, currencyCode: String) -> Single<Analytics> {
        let parameters: Parameters = [
            "currency": currencyCode.lowercased()
        ]

        return networkManager.single(url: "\(baseUrl)/v1/analytics/\(coinUid)", method: .get, parameters: parameters, headers: headers)
    }

    func analyticsPreviewSingle(coinUid: String) -> Single<AnalyticsPreview> {
        networkManager.single(url: "\(baseUrl)/v1/analytics/\(coinUid)/preview", method: .get, headers: headers)
    }

    func dexVolumesSingle(coinUid: String, currencyCode: String, timePeriod: HsTimePeriod) -> Single<DexVolumesResponse> {
        proDataSingle(path: "transactions/dex-volumes", coinUid: coinUid, currencyCode: currencyCode, timePeriod: timePeriod)
    }

    func dexLiquiditySingle(coinUid: String, currencyCode: String, timePeriod: HsTimePeriod) -> Single<DexLiquidityResponse> {
        proDataSingle(path: "transactions/dex-liquidity", coinUid: coinUid, currencyCode: currencyCode, timePeriod: timePeriod)
    }

    func activeAddressesSingle(coinUid: String, timePeriod: HsTimePeriod) -> Single<AddressesResponse> {
        proDataSingle(path: "addresses", coinUid: coinUid, timePeriod: timePeriod)
    }

    func transactionsSingle(coinUid: String, timePeriod: HsTimePeriod) -> Single<TransactionsResponse> {
        proDataSingle(path: "transactions", coinUid: coinUid, timePeriod: timePeriod)
    }

    func cexVolumeRanksSingle(currencyCode: String) -> Single<[RankMultiValue]> {
        rankDataSingle(type: "cex_volume", currencyCode: currencyCode)
    }

    func dexVolumeRanksSingle(currencyCode: String) -> Single<[RankMultiValue]> {
        rankDataSingle(type: "dex_volume", currencyCode: currencyCode)
    }

    func dexLiquidityRanksSingle() -> Single<[RankValue]> {
        rankDataSingle(type: "dex_liquidity")
    }

    func activeAddressRanksSingle() -> Single<[RankMultiValue]> {
        rankDataSingle(type: "address")
    }

    func transactionCountRanksSingle() -> Single<[RankMultiValue]> {
        rankDataSingle(type: "tx_count")
    }

    func revenueRanksSingle(currencyCode: String) -> Single<[RankMultiValue]> {
        rankDataSingle(type: "revenue", currencyCode: currencyCode)
    }

}

extension HsProvider {

    struct HistoricalCoinPriceResponse: ImmutableMappable {
        let timestamp: Int
        let price: Decimal

        init(map: Map) throws {
            timestamp = try map.value("timestamp")
            price = try map.value("price", using: Transform.stringToDecimalTransform)
        }
    }

    struct ChartCoinPriceResponse: ImmutableMappable {
        let timestamp: Int
        let price: Decimal
        let totalVolume: Decimal?

        init(map: Map) throws {
            timestamp = try map.value("timestamp")
            price = try map.value("price", using: Transform.stringToDecimalTransform)
            totalVolume = try? map.value("volume", using: Transform.stringToDecimalTransform)
        }

        var chartPoint: ChartPoint {
            ChartPoint(
                    timestamp: TimeInterval(timestamp),
                    value: price,
                    volume: totalVolume
            )
        }

        var volumeChartPoint: ChartPoint? {
            guard let totalVolume else {
                return nil
            }

            return ChartPoint(timestamp: TimeInterval(timestamp), value: totalVolume)
        }

    }

}