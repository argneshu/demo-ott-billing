import { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import '../App.css'

function InfoIcon() {
  return (
    <svg
      className="info-icon"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <circle cx="12" cy="12" r="10" />
      <line x1="12" y1="16" x2="12" y2="12" />
      <line x1="12" y1="8" x2="12.01" y2="8" />
    </svg>
  )
}

function UsageIcon({ id }) {
  const iconStyle = { width: 18, height: 18, color: '#475569' }
  if (id === 'video-quality') {
    return (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={iconStyle}>
        <circle cx="12" cy="12" r="10" />
        <polygon points="10 8 16 12 10 16 10 8" fill="currentColor" stroke="none" />
      </svg>
    )
  }
  if (id === 'screens') {
    return (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={iconStyle}>
        <rect x="2" y="4" width="14" height="10" rx="1" />
        <path d="M6 18h6" />
        <path d="M9 14v4" />
        <rect x="17" y="9" width="5" height="8" rx="1" />
      </svg>
    )
  }
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={iconStyle}>
      <path d="M12 3v12" />
      <path d="M7 10l5 5 5-5" />
      <path d="M4 20h16" />
    </svg>
  )
}

function IncludedUsageCard({ data }) {
  return (
    <div className="extra-card">
      <div className="extra-title">
        {data.title} <InfoIcon />
      </div>
      {data.items.map((item) => (
        <div key={item.id} className="extra-row">
          <div className="extra-row-header">
            <span>{item.label}</span>
            <span>{item.used_percent}% used</span>
          </div>
          <div className="usage-bar">
            <div
              className="usage-bar-fill"
              style={{ width: `${Math.min(100, item.used_percent)}%` }}
            />
          </div>
        </div>
      ))}
    </div>
  )
}

export default function Billing() {
  const { token } = useAuth()
  const [data, setData] = useState(null)

  useEffect(() => {
    fetch(`/api/billing?email=${encodeURIComponent(token)}`)
      .then((r) => r.json())
      .then(setData)
  }, [token])

  if (!data) {
    return (
      <div className="page-card">
        <p>Loading billing...</p>
      </div>
    )
  }

  return (
    <div className="page-card">
      <div className="billing-header">
        <div className="billing-titles">
          <h2>Plan & Billing</h2>
          <p>Manage your plan and payments</p>
        </div>
      </div>

      <p className="current-label">
        Current plan: <span className="standard-badge">Standard</span>
      </p>
      <p className="section-sub">Unlimited movies, TV shows and more. Watch anywhere. Cancel anytime.</p>

      <div className="plan-row">
        <div className="plan-card">
          <div className="plan-top">
            <div>
              <div className="plan-label">Monthly plan</div>
              <p className="plan-price">{data.price}</p>
            </div>
            <div className="badge-group">
              <span className="badge active">Active</span>
            </div>
          </div>
        </div>
        <div className="renew-card">
          <div className="renew-title">Renew at</div>
          <div className="renew-date">{data.renew_at}</div>
        </div>
      </div>

      <div className="section-title">What's included with Standard</div>
      <p className="section-sub">Your plan's streaming features</p>

      <div className="usage-grid">
        {data.usages.map((u) => (
          <div key={u.id} className="usage-card">
            <div className="tooltip">{u.help}</div>
            <div className="usage-icon">
              <UsageIcon id={u.id} />
            </div>
            <div className="usage-label">{u.label}</div>
            {u.type === 'feature' ? (
              <div className="usage-value">{u.value}</div>
            ) : (
              <>
                <div className="usage-value">
                  {u.used} of {u.total}
                </div>
                <div className="usage-bar">
                  <div
                    className="usage-bar-fill"
                    style={{
                      width: `${Math.min(100, (u.used / u.total) * 100)}%`,
                    }}
                  />
                </div>
              </>
            )}
          </div>
        ))}
      </div>

      <div className="usage-extras usage-extras-single">
        <IncludedUsageCard data={data.included_usage} />
      </div>
    </div>
  )
}
