RSpec.shared_examples 'additional metrics query' do
  include Prometheus::MetricBuilders

  let(:metric_group_class) { Gitlab::Prometheus::MetricGroup }
  let(:metric_class) { Gitlab::Prometheus::Metric }

  let(:metric_names) { %w{metric_a metric_b} }

  let(:query_range_result) do
    [{ 'metric': {}, 'values': [[1488758662.506, '0.00002996364761904785'], [1488758722.506, '0.00003090239047619091']] }]
  end

  before do
    allow(client).to receive(:label_values).and_return(metric_names)
    allow(metric_group_class).to receive(:all).and_return([simple_metric_group(metrics: [simple_metric])])
  end

  context 'with one group where two metrics is found' do
    before do
      allow(metric_group_class).to receive(:all).and_return([simple_metric_group])
    end

    context 'some queries return results' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_b', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_empty', any_args).and_return([])
      end

      it 'return group data only for queries with results' do
        expected = [
          {
            group: 'name',
            priority: 1,
            metrics: [
              {
                title: 'title', weight: nil, y_label: 'Values', queries: [
                { query_range: 'query_range_a', result: query_range_result },
                { query_range: 'query_range_b', label: 'label', unit: 'unit', result: query_range_result }
              ]
              }
            ]
          }
        ]

        expect(query_result).to eq(expected)
      end
    end
  end

  context 'with two groups with one metric each' do
    let(:metrics) { [simple_metric(queries: [simple_query])] }
    before do
      allow(metric_group_class).to receive(:all).and_return(
        [
          simple_metric_group(name: 'group_a', metrics: [simple_metric(queries: [simple_query])]),
          simple_metric_group(name: 'group_b', metrics: [simple_metric(title: 'title_b', queries: [simple_query('b')])])
        ])
      allow(client).to receive(:label_values).and_return(metric_names)
    end

    context 'both queries return results' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_b', any_args).and_return(query_range_result)
      end

      it 'return group data both queries' do
        expected = [
          {
            group: 'group_a',
            priority: 1,
            metrics: [
              {
                title: 'title',
                weight: nil,
                y_label: 'Values',
                queries: [
                  {
                    query_range: 'query_range_a',
                    result: [
                      {
                        metric: {},
                        values: [[1488758662.506, '0.00002996364761904785'], [1488758722.506, '0.00003090239047619091']] }
                    ]
                  }
                ]
              }
            ]
          },
          {
            group: 'group_b',
            priority: 1,
            metrics: [
              {
                title: 'title_b',
                weight: nil,
                y_label: 'Values',
                queries: [
                  {
                    query_range: 'query_range_b', result: [
                    {
                      metric: {},
                      values: [[1488758662.506, '0.00002996364761904785'], [1488758722.506, '0.00003090239047619091']]
                    }
                  ]
                  }
                ]
              }
            ]
          }
        ]

        expect(query_result).to eq(expected)
      end
    end

    context 'one query returns result' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)
        allow(client).to receive(:query_range).with('query_range_b', any_args).and_return([])
      end

      it 'return group data only for query with results' do
        expected = [
          {
            group: 'group_a',
            priority: 1,
            metrics: [
              {
                title: 'title',
                weight: nil,
                y_label: 'Values',
                queries: [
                  {
                    query_range: 'query_range_a',
                    result: query_range_result
                  }
                ]
              }
            ]
          }
        ]

        expect(query_result).to eq(expected)
      end
    end
  end
end